import 'package:cost_calculator/main.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> _login() async {
    final email = emailController.text;
    final password = passwordController.text;

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session != null) {
        // Salvar o email no SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', email);

        // Login bem-sucedido, navegue para a tela principal
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CostCalculatorHomePage()),
        );
      } else {
        _showError('Falha ao fazer login. Verifique suas credenciais.');
      }
    } catch (error) {
      _showError('Erro: $error');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 10),
              Container(
                width: 300,
                height: 203,
                child: Image.asset(
                  'assets/logo1.png',  // Caminho da imagem
                  fit: BoxFit.cover,  // Ajusta a imagem para cobrir o espaço disponível
                ),
              ),
              // Image.asset('assets/logo1.png', fit: BoxFit.cover),
              SizedBox(height: 30),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 20),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              SizedBox(height: 10),
              // Align(
              //   alignment: Alignment.center,
              //   child: TextButton(
              //     onPressed: () {
              //       // Lógica para recuperação de senha será implementada mais tarde
              //     },
              //     child: Text('Esqueci minha senha'),
              //   ),
              // ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _login,
                child: Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
