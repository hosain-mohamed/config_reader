import 'dart:io';

import 'package:xml/xml.dart';

Future<void> androidManifest({
  String bundle,
  String baseUrl,
  String name,
  String adMobId,
  String deeplink,
  String applink,
}) async {
  final path = 'android/app/src/main';

  final file = File('$path/AndroidManifest.xml');
  if (file.existsSync() == false) {
    file.createSync();
  }

  String notiIcon = '';

  final notiFile = File('android/app/src/main/res/drawable/noti_icon.png');
  final colorsFile = File('android/app/src/main/res/values/colors.xml');
  if (notiFile.existsSync() && colorsFile.readAsStringSync().contains('noti_color')) {
    notiIcon = '''
<meta-data
          android:name="com.google.firebase.messaging.default_notification_icon"
          android:resource="@drawable/noti_icon"
          />
        <meta-data
          android:name="com.google.firebase.messaging.default_notification_color"
          android:resource="@color/noti_color"
          />''';
  }

  final xml = XmlDocument.parse(file.readAsStringSync());
  final man = xml.rootElement;
  final oldBundle = man.attributes.firstWhere((e) => e.name.local == 'package', orElse: () => null)?.value ?? 'null';
  final app = man.getElement('application');
  final oldName = app.attributes.firstWhere((e) => e.name.local == 'label', orElse: () => null)?.value ?? 'null';

  final prov = r'${applicationId}.provider';

  final deepLinkHost = deeplink != null ? Uri.parse(deeplink).host : '';
  final deepLinkScheme = deeplink != null ? Uri.parse(deeplink).scheme : '';
  final deepLinkPathPattern = deeplink != null ? Uri.parse(deeplink).path : '';

  final appLinkHost = Uri.parse(applink).host;
  final appLinkPathPattern = Uri.parse(applink).path;

  final applinkPathPatternElement =
      appLinkPathPattern != null && appLinkPathPattern.isNotEmpty ? '\n\t\t\t\t\tandroid:pathPattern="${appLinkPathPattern.startsWith('/') ? '' : '/'}$appLinkPathPattern"' : '';
  final deeplinkPathPatternElement = deepLinkPathPattern != null && deepLinkPathPattern.isNotEmpty
      ? '\n\t\t\t\t\tandroid:pathPattern="${deepLinkPathPattern.startsWith('/') ? '' : '/'}$deepLinkPathPattern"'
      : '';

  file.writeAsStringSync('''
<manifest
    xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools"
    package="$oldBundle"
    >

    <uses-permission android:name="android.permission.INTERNET" />
    <!-- io.flutter.app.FlutterApplication is an android.app.Application that
           calls FlutterMain.startInitialization(this); in its onCreate method.
           In most cases you can leave this as-is, but you if you want to provide
           additional functionality it is fine to subclass or reimplement
           FlutterApplication and put your custom class here. -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    
    <queries>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="https" android:host="youtube.com" />
        </intent>
    </queries>

    <application
        android:name="io.flutter.app.FlutterApplication"
        android:icon="@mipmap/ic_launcher"
        android:label="$oldName"
        tools:replace="android:label,android:name"
        >
        <activity
            android:name=".MainActivity"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:windowSoftInputMode="adjustResize"
            >
            <!-- Specifies an Android theme to apply to this Activity as soon as
                       the Android process has started. This theme is visible to the user
                       while the Flutter UI initializes. After that, this theme continues
                       to determine the Window background behind the Flutter UI. -->
            <!-- <meta-data android:name="io.flutter.embedding.android.NormalTheme" android:resource="@style/NormalTheme" /> -->
            <!-- Displays an Android View that continues showing the launch screen
                       Drawable until Flutter paints its first frame, then this splash
                       screen fades out. A splash screen is useful to avoid any visual
                       gap between the end of Android's launch screen and the painting of
                       Flutter's first frame. -->
            <meta-data
                android:name="io.flutter.embedding.android.SplashScreenDrawable"
                android:resource="@drawable/launch_background"
                />

            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
            <intent-filter>
                <action android:name="FLUTTER_NOTIFICATION_CLICK" />
                <category android:name="android.intent.category.DEFAULT" />
            </intent-filter>
            ${deeplink != null ? '''
            <!-- Deep Links -->
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />

                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />

                <data
                    android:scheme="$deepLinkScheme"
                    android:host="$deepLinkHost"$deeplinkPathPatternElement
                    />
            </intent-filter>
            ''' : ''}
            <!-- App Links -->
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />

                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />

                <data
                    android:scheme="https"
                    android:host="$appLinkHost"$applinkPathPatternElement
                    />
            </intent-filter>
        </activity>
        <!-- Don't delete the meta-data below.
                 This is used by the Flutter tool to generate GeneratedPluginRegistrant.java -->
        <meta-data
            android:name="flutterEmbedding"
            android:value="2"
            />
        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="$adMobId"
            />

        <provider
            android:name="androidx.core.content.FileProvider"
            android:authorities="$prov"
            android:exported="false"
            android:grantUriPermissions="true"
            >
            <meta-data
                android:name="android.support.FILE_PROVIDER_PATHS"
                android:resource="@xml/provider_paths"
                />
        </provider>

        <meta-data
            android:name="com.facebook.sdk.ApplicationId"
            android:value="@string/facebook_app_id"
            />

        <activity
            android:name="com.facebook.FacebookActivity"
            android:configChanges="keyboard|keyboardHidden|screenLayout|screenSize|orientation"
            android:label="@string/app_name"
            />

        <activity
            android:name="com.facebook.CustomTabActivity"
            android:exported="true"
            >
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />

                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />

                <data android:scheme="@string/fb_login_protocol_scheme" />
            </intent-filter>
        </activity>
        
        $notiIcon

    </application>
</manifest>

''');
}

Future<void> debugAndroidManifest(String bundle) async {
  final file = File('android/app/src/debug/AndroidManifest.xml');
  if (file.existsSync() == false) {}
  file.writeAsStringSync('''
<manifest
    xmlns:android="http://schemas.android.com/apk/res/android"
    package="$bundle"
    >
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
</manifest>
  ''');
}

Future<void> profileAndroidManifest(String bundle) async {
  final file = File('android/app/src/profile/AndroidManifest.xml');
  if (file.existsSync() == false) {}
  file.writeAsStringSync('''
<manifest
    xmlns:android="http://schemas.android.com/apk/res/android"
    package="$bundle"
    >
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
</manifest>
  ''');
}
