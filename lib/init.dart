import 'package:config_reader/colors.dart';
import 'package:config_reader/pubspec.dart';
import 'package:config_reader/runner_entitlements.dart';
import 'package:config_reader/strings_xml.dart';
import 'package:config_reader/temp_json.dart';
import 'package:config_reader/utils/utils.dart';
import 'package:config_reader/version.dart';
import 'package:process_run/shell_run.dart';

import 'android_manifest.dart';
import 'app_file.dart';
import 'config_reader.dart';
import 'download_images.dart';
import 'flutter_launcher_icons.dart';
import 'flutter_launcher_name.dart';
import 'flutter_native_splash.dart';
import 'git_ignore.dart';
import 'google_services_plist.dart';
import 'info_plist.dart';
import 'utils.dart';

final shell = Shell();

Future<void> init({
  bool local = false,
  bool addToGit = false,
  bool incrementIOS = false,
  bool incrementAndroid = false,
}) async {
  final staticConfig = await getStaticConfig();
  final config = await getConfig(staticConfig);

  final adMobId = config.getMap('meta')?.getMap('ads')?.getMap('google')?.get('id') ?? 'ca-app-pub-3102006508276410~8783578315';
  final adMobIOSId = config.getMap('meta')?.getMap('ads')?.getMap('ios')?.get('id') ?? 'ca-app-pub-3102006508276410~8783578315';
  
  final facebookId = config.getMap('meta')?.getMap('socialLogin')?.getMap('facebook')?.get('id');
  final facebookName = config.getMap('meta')?.getMap('socialLogin')?.getMap('facebook')?.get('name');
  final appName = tryString(config.getMap('meta')?.getMap('app')?.get('appName'), staticConfig.get('appName'));
  final appBundleAndroid = staticConfig.get('appIdAndroid');
  final appBundleIOS = staticConfig.get('appIdIOS');
  final baseUrl = config.getMap('meta')?.get('baseUrl') ?? staticConfig.get('serviceUrl') ?? staticConfig.get('baseUrl');

  final keyId = config.getMap('meta')?.getMap('ios')?.get('keyId');
  final issuerId = config.getMap('meta')?.getMap('ios')?.get('issuerId');
  final authKey = config.getMap('meta')?.getMap('ios')?.get('authKey');
  final nSUserTrackingUsageDescription = config.getMap('meta')?.getMap('ios')?.get('att') ?? 'This identifier will be used to deliver personalized ads to you.';

  final String applink = tryString(config.getMap('meta')?.get('applink'), baseUrl);
  final String deeplink = config.getMap('meta')?.get('deeplink');

  // final adMobIdAndroid = config.getMap('meta')?.getMap('adMob')?.get('androidID') ?? 'GAD_Android';
  // final adMobIdIOS = config.getMap('meta')?.getMap('adMob')?.get('IosID') ?? 'GAD_IOS';

  final splashColor = config.getMap('meta')?.getMap('splash')?.get('color');
  final splashUrl = config.getMap('meta')?.getMap('splash')?.get('image');

  final iconUrl = config.getMap('meta')?.getMap('app')?.get('appIcon');

  final notiIconUrl = config.getMap('meta')?.getMap('notifications')?.get('icon');
  final notiColor = config.getMap('meta')?.getMap('notifications')?.get('color');

  final versionsMap = await versions();
  if (incrementIOS && versionsMap == null) {
    print('Please set the last ios version to CFBundleShortVersionString in ios/Runner/Info.plist file');
    return;
  }
  final iosVersion = versionsMap?.get('ios');
  final androidVersion = versionsMap?.get('android');

  await downloadImages(
    splashUrl: splashUrl,
    iconUrl: iconUrl,
    notiIconUrl: notiIconUrl,
  );

  await colors(
    notiColor: notiColor,
  );

  // await createSplash('FF0000');
  // await createIconsFromArguments([]);

  // await changeGradle(staticConfig['appIdAndroid']);
  // await changePackageName(staticConfig['appIdAndroid']);
  // await debugAndroidManifest(staticConfig['appIdAndroid']);
  // await profileAndroidManifest(staticConfig['appIdAndroid']);

  await appFile(appBundleAndroid);

  await tempJson(
    authKey: authKey,
    issuerId: issuerId,
    keyId: keyId,
  );

  await androidManifest(
    bundle: appBundleAndroid,
    baseUrl: baseUrl,
    name: appName,
    adMobId: adMobId,
    deeplink: deeplink,
    applink: applink,
  );

  await infoPlist(
    bundle: appBundleIOS,
    version: incrementIOS ? iosVersion : null,
    facebookId: facebookId,
    facebookName: facebookName,
    reversedClientId: await getReversedClientId(),
    nSUserTrackingUsageDescription: nSUserTrackingUsageDescription,
    adMobId: adMobIOSId,
    deeplink: deeplink,
  );

  await runnerEntitlements(
    applink: applink,
  );

  await parseFacebook(
    facebookId: facebookId,
    facebookName: facebookName,
  );

  await changePubspec(
    remoteConfigReaderDep: !local,
    version: incrementAndroid ? androidVersion : null,
  );

  await flutterLauncherIcons();
  await flutterLauncherName(appName);
  await flutterNativeSplash(splashColor);

  final clean = 'flutter clean';
  final pubGet = 'flutter pub get';
  final splash = 'flutter pub pub run flutter_native_splash:create';
  final icons = 'flutter pub run flutter_launcher_icons:main';
  final name = 'flutter pub run custom_flutter_launcher_name:main';
  final bundle = 'flutter pub run change_app_package_name:main $appBundleAndroid';
  final gitAdd = 'git add .';

  await shell.run(clean);
  await shell.run(pubGet);
  await shell.run(bundle);
  await shell.run(splash);
  await shell.run(icons);
  await shell.run(name);

  if (addToGit) {
    await commentGitIgnore();
    await shell.run(gitAdd);
    await commentGitIgnore(reverse: true);
  }
}
