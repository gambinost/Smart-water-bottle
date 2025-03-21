import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // setting a controller for each input field so we can fetch it later using firestore features
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late TextEditingController ageController;
  String selectedGender = 'Male';
  @override
  void initState() {
    emailController = TextEditingController();
    passwordController = TextEditingController();
    ageController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //runs main widgets each time with application
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register"),
        backgroundColor: const Color(0xFF86B9D6),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/water.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF86B9D6).withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color.fromARGB(255, 59, 129, 170),
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                // for controlling the render flex problem
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Email Field
                    _buildTextField(
                      controller: emailController,
                      hintText: 'Email',
                      icon: Icons.email,
                    ),
                    const SizedBox(height: 20),

                    // Password Field
                    _buildTextField(
                      controller: passwordController,
                      hintText: 'Password',
                      icon: Icons.lock,
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),
                    // Age Field
                    _buildTextField(
                      controller: ageController,
                      hintText: 'Age',
                      icon: Icons.calendar_today,
                    ),
                    const SizedBox(height: 20),

                    // Gender Dropdown
                    SizedBox(
                      width: 300,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 96, 191, 247),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedGender,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down,
                                color: Colors.black),
                            style: const TextStyle(color: Colors.black),
                            onChanged: (String? newValue) {
                              setState(() {
                                if (newValue != null) {
                                  selectedGender = newValue;
                                }
                              });
                            },
                            items: <String>['Male', 'Female']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Register Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: SizedBox(
                        width: 200,
                        child: ElevatedButton(
                          onPressed: () async {
                            //trimming the data to use it later
                            String email = emailController.text.trim();
                            String password = passwordController.text.trim();
                            String age = ageController.text.trim();
                            // if any field found empty an alert will be shown
                            if (email.isEmpty ||
                                password.isEmpty ||
                                age.isEmpty ||
                                selectedGender.isEmpty) {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text("Error"),
                                    content:
                                        const Text("All fields are required."),
                                    actions: [
                                      TextButton(
                                        child: const Text("OK"),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                              // the national id should be consisting of 14 number
                            } else {
                              // the authentication part the keyword await here shows that we can't go further unless the authentication is done correctly
                              try {
                                UserCredential userCredential =
                                    await FirebaseAuth.instance
                                        .createUserWithEmailAndPassword(
                                  email: emailController.text,
                                  password: passwordController.text,
                                );
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(userCredential.user?.uid)
                                    .set({
                                      'age': age,
                                      'email': email,
                                      'gender': selectedGender,
                                    })
                                    .then((value) => print('User Added'))
                                    .catchError((error) =>
                                        print('Failed to add user: $error'));

                                Navigator.pushReplacementNamed(
                                    context, '/homepage');
                                // a catch if anything wrong happend with the firestore end
                              } catch (e) {
                                setState(() {
                                  String errorMessage =
                                      "Failed to register: $e";
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text("error : failed to register"),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                });
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 25),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            backgroundColor: Colors.blue.withOpacity(0.6),
                          ),
                          child: const Text('Register'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 96, 191, 247),
        borderRadius: BorderRadius.circular(30),
      ),
      child: SizedBox(
        width: 300,
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.black),
            hintText: hintText,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
            hintStyle: const TextStyle(color: Colors.black),
          ),
          style: const TextStyle(color: Colors.black),
        ),
      ),
    );
  }
}
