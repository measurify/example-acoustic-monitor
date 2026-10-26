import 'package:flutter/material.dart';
import '../controllers/monitoring_controller.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.controller});
  final MonitoringController controller;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.initialize();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    final message = widget.controller.latestUiMessage;
    if (message.isNotEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.fixed,
          ),
        );
      widget.controller.clearLatestUiMessage();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acoustic Monitor', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(onPressed: c.manualReconnect, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: switch (c.selectedPage) {
            DashboardPage.home => _HomePage(controller: c),
            DashboardPage.fft => _FftPage(controller: c),
            DashboardPage.accelerometer => _AccelerometerPage(controller: c),
            DashboardPage.debug => _DebugPage(controller: c),
          },
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: DashboardPage.values.indexOf(c.selectedPage),
        onDestinationSelected: (index) => c.changeSelectedPage(DashboardPage.values[index]),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.graphic_eq_rounded), label: 'FFT'),
          NavigationDestination(icon: Icon(Icons.vibration_rounded), label: 'Assi'),
          NavigationDestination(icon: Icon(Icons.code_rounded), label: 'Debug'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (!c.isRecording) {
            c.startRecording();
          } else {
            await c.stopRecordingAndExport();
          }
        },
        backgroundColor: c.isRecording ? AppTheme.red : AppTheme.cyan,
        foregroundColor: c.isRecording ? Colors.white : const Color(0xFF041214),
        icon: Icon(c.isRecording ? Icons.stop_rounded : Icons.fiber_manual_record_rounded),
        label: Text(c.isRecording ? 'Stop ${c.recordingElapsedLabel}' : 'Registra CSV'),
      ),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage({required this.controller});
  final MonitoringController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('home'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      children: [
        _TopBanner(controller: controller),
        const SizedBox(height: 16),
        _AlarmStackCard(controller: controller),
        const SizedBox(height: 16),
        _HomeHeroMetrics(controller: controller),
        const SizedBox(height: 16),
        
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton.icon(
            onPressed: () => controller.sendCurrentPointToMeasurify(),
            icon: const Icon(Icons.cloud_upload_rounded),
            label: const Text(
              'Invia a Measurify',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Contatori sessione',
          subtitle: 'Stato rapido della ricezione locale e invio al cloud.',
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _CompactInfoCard(
                  title: 'Pacchetti ricevuti',
                  value: '${controller.packetsReceived}',
                  icon: Icons.move_to_inbox_rounded,
                  color: AppTheme.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CompactInfoCard(
                  title: 'Inviati a Measurify',
                  value: '${controller.packetsSentToMeasurify}',
                  icon: Icons.cloud_upload_rounded,
                  color: AppTheme.cyan,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FftPage extends StatelessWidget {
  const _FftPage({required this.controller});
  final MonitoringController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('fft'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      children: [
        _SectionCard(
          title: 'Analisi FFT',
          subtitle: 'Le bande sono riportate con un range di frequenze indicativo.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FftBars(values: controller.fftBands, tall: true),
              const SizedBox(height: 16),
              Column(
                children: List.generate(controller.fftBands.length, (index) {
                  final value = controller.fftBands[index].toStringAsFixed(1);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceAlt,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.stroke),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppTheme.cyan.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text('B${index + 1}', style: const TextStyle(color: AppTheme.cyan, fontWeight: FontWeight.w800, fontSize: 12)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(controller.fftBandRangeLabel(index), style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 13.5)),
                                const SizedBox(height: 2),
                                Text(controller.fftBandLabel(index), style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(value, style: const TextStyle(color: AppTheme.cyan, fontWeight: FontWeight.w800, fontSize: 15)),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccelerometerPage extends StatelessWidget {
  const _AccelerometerPage({required this.controller});
  final MonitoringController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('acc'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      children: [
        _SectionCard(
          title: 'Assi accelerometrici',
          subtitle: 'Monitoraggio continuo delle vibrazioni sugli assi X, Y e Z.',
          child: Column(
            children: [
              _AxisProgress(label: 'Asse X', value: controller.accX, color: const Color(0xFFFF9F43)),
              const SizedBox(height: 14),
              _AxisProgress(label: 'Asse Y', value: controller.accY, color: AppTheme.green),
              const SizedBox(height: 14),
              _AxisProgress(label: 'Asse Z', value: controller.accZ, color: AppTheme.blue),
            ],
          ),
        ),
      ],
    );
  }
}

class _DebugPage extends StatelessWidget {
  const _DebugPage({required this.controller});
  final MonitoringController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('debug'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      children: [
        _SectionCard(
          title: 'Indice errori possibili',
          subtitle: 'Riepilogo rapido dei problemi più comuni e del loro significato.',
          child: Column(
            children: controller.debugIssues.map((issue) {
              return Padding(padding: const EdgeInsets.only(bottom: 10), child: _IssueTile(issue: issue));
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Debug connessione',
          subtitle: 'Informazioni tecniche utili per diagnosi rapida.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DebugLine(label: 'Endpoint', value: controller.websocketUrl),
              _DebugLine(label: 'Stato', value: controller.connectionLabel),
              _DebugLine(label: 'Tentativi reconnect', value: '${controller.reconnectAttempt}'),
              _DebugLine(label: 'Pacchetti ricevuti', value: '${controller.packetsReceived}'),
              _DebugLine(label: 'Inviati a Measurify', value: '${controller.packetsSentToMeasurify}'),
              _DebugLine(label: 'Ultimo pacchetto', value: controller.lastPacketAt?.toIso8601String() ?? 'mai'),
              _DebugLine(label: 'Ultimo errore', value: controller.lastError.isEmpty ? '-' : controller.lastError),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Ultimo pacchetto grezzo',
          subtitle: 'Vista estesa del payload ricevuto.',
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceAlt,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.stroke),
            ),
            child: SelectableText(
              controller.rawLastPacket,
              style: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted, height: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}

class _TopBanner extends StatelessWidget {
  const _TopBanner({required this.controller});
  final MonitoringController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (controller.connectionState) {
      ConnectionStateView.connected => AppTheme.green,
      ConnectionStateView.connecting => AppTheme.orange,
      ConnectionStateView.reconnecting => const Color(0xFFFF9F43),
      ConnectionStateView.error => AppTheme.red,
      ConnectionStateView.disconnected => AppTheme.red,
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.20), scheme.surface], 
          begin: Alignment.topLeft, 
          end: Alignment.bottomRight
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Text(
                controller.connectionLabel, 
                style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Endpoint: ${controller.websocketUrl}', 
            maxLines: 1, 
            overflow: TextOverflow.ellipsis
          ),
          Text(
            'Tentativi reconnect: ${controller.reconnectAttempt}', 
            maxLines: 1, 
            overflow: TextOverflow.ellipsis
          ),
          Text(
            'Ultimo errore: ${controller.lastError.isEmpty ? '-' : controller.lastError}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _AlarmStackCard extends StatelessWidget {
  const _AlarmStackCard({required this.controller});
  final MonitoringController controller;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Allarmi attivi',
      subtitle: controller.hasActiveAlarms ? 'Visualizzati in ordine di priorità.' : 'Nessun allarme attivo al momento.',
      child: controller.hasActiveAlarms
          ? Column(
              children: controller.activeAlarms.map((alarm) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AlarmTile(title: alarm.title, description: alarm.description, color: controller.colorForAlarm(alarm.kind)),
              )).toList(),
            )
          : const _AlarmTile(title: 'Sistema stabile', description: 'Nessuna condizione critica rilevata.', color: AppTheme.green),
    );
  }
}

class _HomeHeroMetrics extends StatelessWidget {
  const _HomeHeroMetrics({required this.controller});
  final MonitoringController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 6, child: _MetricCard(title: 'dB(A)', value: controller.currentDba.toStringAsFixed(1), subtitle: 'Livello sonoro attuale', color: AppTheme.green, icon: Icons.graphic_eq_rounded)),
        const SizedBox(width: 12),
        Expanded(
          flex: 5,
          child: Column(
            children: [
              _MiniMetric(title: 'Acc X', value: controller.accX, color: const Color(0xFFFF9F43)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _MiniMetric(title: 'Acc Y', value: controller.accY, color: AppTheme.green)),
                  const SizedBox(width: 12),
                  Expanded(child: _MiniMetric(title: 'Acc Z', value: controller.accZ, color: AppTheme.blue)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactInfoCard extends StatelessWidget {
  const _CompactInfoCard({required this.title, required this.value, required this.icon, required this.color});
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.stroke)),
      child: Row(
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.15)),
                const SizedBox(height: 6),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlarmTile extends StatelessWidget {
  const _AlarmTile({required this.title, required this.description, required this.color});
  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(18), border: Border.all(color: color.withOpacity(0.50))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.notifications_active_rounded, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 15.5)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueTile extends StatelessWidget {
  const _IssueTile({required this.issue});
  final DebugIssue issue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: issue.color.withOpacity(0.10), borderRadius: BorderRadius.circular(18), border: Border.all(color: issue.color.withOpacity(0.42))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: issue.color.withOpacity(0.16), borderRadius: BorderRadius.circular(14)), child: Icon(issue.icon, color: issue.color, size: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(issue.title, style: TextStyle(color: issue.color, fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 4),
                Text(issue.description, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.subtitle});
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            if (subtitle != null) ...[const SizedBox(height: 6), Text(subtitle!, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13))],
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value, required this.subtitle, required this.color, required this.icon});
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 160),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12.5))),
                  const SizedBox(width: 8),
                  Icon(icon, color: color),
                ],
              ),
              const SizedBox(height: 12),
              FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, maxLines: 1, style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: color))),
              const SizedBox(height: 6),
              Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.title, required this.value, required this.color});
  final String title;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 84, maxHeight: 92),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12.5)),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown, 
                alignment: Alignment.centerLeft, 
                child: Text(
                  value.toStringAsFixed(2),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FftBars extends StatelessWidget {
  const _FftBars({required this.values, this.tall = false});
  final List<double> values;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    final double height = tall ? 220 : 130;
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: values.map((v) {
          final normalized = v <= 0 ? 6.0 : v.clamp(6.0, tall ? 200.0 : 110.0).toDouble();
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                height: normalized,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(colors: [AppTheme.cyan, AppTheme.blue], begin: Alignment.bottomCenter, end: Alignment.topCenter),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AxisProgress extends StatelessWidget {
  const _AxisProgress({required this.label, required this.value, required this.color});
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final normalized = (value.abs() / 30).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(value.toStringAsFixed(2), style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 12,
            value: normalized,
            backgroundColor: AppTheme.surfaceAlt,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _DebugLine extends StatelessWidget {
  const _DebugLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13.5),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
            TextSpan(text: value, style: const TextStyle(color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }
}