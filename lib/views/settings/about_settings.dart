import 'package:fluent_ui/fluent_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutSettingsPage extends StatelessWidget {
  const AboutSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: const PageHeader(
        title: Text('关于软件'),
      ),
      content: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FlutterLogo(size: 100),
            const SizedBox(height: 20),
            const Text(
              'Lappy',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('版本号：0.1.1'),
            const SizedBox(height: 20),
            HyperlinkButton(
              onPressed: () async {
                final Uri url = Uri.parse('https://github.com/Neuromian/Lappy');
                await launchUrl(url, mode: LaunchMode.externalApplication);
              },
              child: const Icon(
                FluentIcons.open_source,
                size: 24,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton(
                  onPressed: () {
                    displayInfoBar(
                      context,
                      duration: const Duration(seconds: 2),
                      builder: (context, close) => const InfoBar(
                        title: Text('功能开发中'),
                        severity: InfoBarSeverity.info,
                      ),
                    );
                  },
                  child: const Text('官方网站'),
                ),
                const SizedBox(width: 20),
                FilledButton(
                  onPressed: () {
                    displayInfoBar(
                      context,
                      duration: const Duration(seconds: 2),
                      builder: (context, close) => const InfoBar(
                        title: Text('功能开发中'),
                        severity: InfoBarSeverity.info,
                      ),
                    );
                  },
                  child: const Text('小红书'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}