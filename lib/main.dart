import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/ride_request_controller.dart';
import 'controllers/taxi_controller.dart';
import 'firebase_options.dart';
import 'screens/customer_home_screen.dart';
import 'screens/driver_registration_screen.dart';
import 'controllers/driver_registration_controller.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
  ChangeNotifierProvider<TaxiController>(
    create: (_) => TaxiController(),
  ),
  ChangeNotifierProvider<DriverRegistrationController>(
    create: (_) => DriverRegistrationController(),
  ),
  ChangeNotifierProvider(
  create: (_) => RideRequestController(),
),
],
      child: const TaksioApp(),
    ),
  );
}

class TaksioApp extends StatelessWidget {
  const TaksioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TAKSIO',
      theme: ThemeData(scaffoldBackgroundColor: Colors.black),
      home: const SplashScreen(),
    );
  }
}

class AppColors {
  static const Color yellow = Color(0xFFFFC107);
  static const Color black = Color(0xFF050505);
  static const Color darkGray = Color(0xFF151515);
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.black,
      body: Center(child: TaksioLogo()),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const TaksioLogo(),
              const SizedBox(height: 36),
              const Text(
                'TAKSIO’ya Hoş Geldin',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              const Text(
                'En yakın taksiyi tek dokunuşla çağır veya taksici olarak sisteme katıl.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
              ),
              const Spacer(),
              TaksioButton(
                text: 'Müşteri Olarak Devam Et',
                backgroundColor: AppColors.yellow,
                textColor: Colors.black,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CustomerLoginScreen()),
                  );
                },
              ),
              const SizedBox(height: 14),
              TaksioButton(
  text: 'Taksici Olarak Devam Et',
  backgroundColor: AppColors.darkGray,
  textColor: Colors.white,
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DriverRegistrationScreen(),
      ),
    );
  },
),  
            ],
          ),
        ),
      ),
    );
  }
}

class CustomerLoginScreen extends StatefulWidget {
  const CustomerLoginScreen({super.key});

  @override
  State<CustomerLoginScreen> createState() => _CustomerLoginScreenState();
}

class _CustomerLoginScreenState extends State<CustomerLoginScreen> {
  final TextEditingController phoneController = TextEditingController();

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  void goToOtpScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtpScreen(phoneNumber: phoneController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(backgroundColor: AppColors.black, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Müşteri Girişi',
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              const Text(
                'Telefon numaranı gir, TAKSIO ile sana en yakın taksiyi çağıralım.',
                style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 36),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '5XX XXX XX XX',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixText: '+90 ',
                  prefixStyle: const TextStyle(color: AppColors.yellow, fontWeight: FontWeight.bold),
                  filled: true,
                  fillColor: AppColors.darkGray,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const Spacer(),
              TaksioButton(
                text: 'Devam Et',
                backgroundColor: AppColors.yellow,
                textColor: Colors.black,
                onPressed: goToOtpScreen,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class OtpScreen extends StatelessWidget {
  final String phoneNumber;

  const OtpScreen({super.key, required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(backgroundColor: AppColors.black, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Doğrulama Kodu',
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Text(
                '+90 $phoneNumber numarasına gönderilen 6 haneli kodu gir.',
                style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 36),
              TextField(
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '------',
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: AppColors.darkGray,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const Spacer(),
              TaksioButton(
                text: 'Doğrula ve Devam Et',
                backgroundColor: AppColors.yellow,
                textColor: Colors.black,
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const CustomerHomeScreen()),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}


class TaksioLogo extends StatelessWidget {
  const TaksioLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 108,
          height: 108,
          decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(30)),
          child: const Icon(Icons.local_taxi, color: Colors.black, size: 62),
        ),
        const SizedBox(height: 22),
        const Text(
          'TAKSIO',
          style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 3),
        ),
        const SizedBox(height: 8),
        const Text(
          'En Yakın Taksi, Tek Dokunuş.',
          style: TextStyle(color: AppColors.yellow, fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class TaksioButton extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onPressed;

  const TaksioButton({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onPressed,
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}