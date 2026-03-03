
$content = Get-Content D:\FlutterApps\railfocus\lib\main.dart -Raw
$newContent = $content + "`n`n// --------------------------------------------------------------`n// ROOT APP WIDGET`n// --------------------------------------------------------------`n`nclass RailFocusApp extends StatelessWidget {`n  const RailFocusApp({super.key});`n`n  @override`n  Widget build(BuildContext context) {`n    return MaterialApp.router(`n      title: 'RailFocus',`n      debugShowCheckedModeBanner: false,`n      theme: AppTheme.darkTheme,`n      routerConfig: appRouter,`n      showPerformanceOverlay: false,`n    );`n`n  }`n}`n"
Set-Content -Path D:\FlutterApps\railfocus\lib\main.dart -Value $newContent

