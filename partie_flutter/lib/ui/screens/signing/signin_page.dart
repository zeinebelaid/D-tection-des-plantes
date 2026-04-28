import 'package:chaatbot_detection/firstpage.dart';
import 'package:flutter/material.dart';
import 'package:chaatbot_detection/ui/screens/signing/authentification.dart';
import 'package:chaatbot_detection/utils/constants.dart';
import 'package:chaatbot_detection/ui/screens/rootage/root_page2.dart';
// import 'package:chaatbot_detection/ui/screens/signing/signup_page.dart';
import 'package:page_transition/page_transition.dart';
import 'package:chaatbot_detection/models/user.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthenticationService _authService = AuthenticationService();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final response = await _authService.signInUser(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (response == "User signed in successfully!") {
      final Users? userData = await _authService.getUserData();

      if (userData != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Signed in successfully'),
              backgroundColor: Colors.green),
        );

        final Widget target =
            userData.role == 'user' ? const MyApp() : const RootPage2();

        // Replace current screen; switch to pushAndRemoveUntil if you want to clear the entire stack.
        Navigator.pushReplacement(
          context,
          PageTransition(child: target, type: PageTransitionType.bottomToTop),
        );
        // Or:
        // Navigator.pushAndRemoveUntil(
        //   context,
        //   PageTransition(child: target, type: PageTransitionType.bottomToTop),
        //   (route) => false,
        // );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('User data not found'),
              backgroundColor: Colors.red),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(response ?? 'An unexpected error occurred.'),
            backgroundColor: Colors.red),
      );
    }

    setState(() => _isLoading = false);
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'At least 6 characters';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      'Sign In',
                      style:
                          TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.alternate_email),
                        border: OutlineInputBorder(),
                      ),
                      validator: _emailValidator,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      validator: _passwordValidator,
                      onFieldSubmitted: (_) => _signInUser(),
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: size.width,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signInUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Constants.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Sign In'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                    ),
                    const SizedBox(height: 24),
                    // Row(
                    //   children: const [
                    //     Expanded(child: Divider()),
                    //     Padding(
                    //         padding: EdgeInsets.symmetric(horizontal: 10),
                    //         child: Text('OR')),
                    //     Expanded(child: Divider()),
                    //   ],
                    // ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // const Text("New to Planty? "),
                        // TextButton(
                        //   onPressed: () {
                        //     Navigator.pushReplacement(
                        //       context,
                        //       PageTransition(
                        //         // child: const SignUp(),
                        //         type: PageTransitionType.bottomToTop,
                        //       ),
                        //     );
                        //   },
                        //   child: Text(
                        //     'Register',
                        //     style: TextStyle(color: Constants.primaryColor),
                        //   ),
                        // ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
