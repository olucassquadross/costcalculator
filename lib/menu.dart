import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'main.dart'; // Importar para poder navegar para CostCalculatorHomePage

class MenuPage extends StatefulWidget {
  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  String? userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('user_email');
    });
  }

  Future<void> _logout() async {
    // Limpa o email salvo no SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');

    await supabase.auth.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false,
    );
  }

  Future<void> _changePassword() async {
    // Envia o link de redefinição de senha para o e-mail do usuário
    if (userEmail != null) {
      await supabase.auth.resetPasswordForEmail(userEmail!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Link de redefinição de senha enviado para $userEmail')),
      );
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      // Navega para a tela principal
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CostCalculatorHomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Menu'),
        backgroundColor: Color.fromARGB(255, 241, 241, 241),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card para as informações da conta
              if (userEmail != null) ...[
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 70),
                          child: Icon(
                            Icons.person,
                            size: 150,
                            color: Color.fromARGB(255, 255, 115, 31),
                          ),
                        ),
                        SizedBox(height: 20),
                        const Padding(
                          padding: EdgeInsets.only(left: 13),
                          child: Text(
                            'Conta',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.only(left: 13),
                          child: Row(
                            children: [
                              const Icon(Icons.email, color: Color.fromARGB(255, 255, 115, 31)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  userEmail!,
                                  style: const TextStyle(fontSize: 18, color: Colors.black54),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        // Align(
                        //   alignment: Alignment.centerLeft,
                        //   child: TextButton.icon(
                        //     onPressed: _changePassword,
                        //     icon: Icon(Icons.lock_reset, color: Colors.blue),
                        //     label: Text(
                        //       'Alterar Senha',
                        //       style: TextStyle(color: Colors.blue, fontSize: 16),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
              ],
              SizedBox(height: 20),

              // Card para o botão de logout
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                color: Colors.redAccent,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        'Deseja sair?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _logout,
                        icon: Icon(Icons.exit_to_app, color: Colors.white),
                        label: Text('Sair'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white, backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: 'Menu',
          ),
        ],
        selectedItemColor: Color.fromARGB(255, 255, 115, 31),
        unselectedItemColor: Colors.grey,
        currentIndex: 1,
        onTap: _onItemTapped,
      ),
    );
  }
}
