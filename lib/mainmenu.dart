import 'package:flutter/material.dart';
import 'package:quiz/quizpage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainMenu extends StatefulWidget {
  @override
  _MainMenuState createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  int? _savedScore;
  int? _savedCorrectAnswers;

  @override
  void initState() {
    super.initState();
    _loadSavedScore();
  }

  Future<void> _loadSavedScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedScore = prefs.getInt('score') ?? 0;
      _savedCorrectAnswers = prefs.getInt('correctAnswers') ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz App',style: TextStyle(fontWeight: FontWeight.w400,color: Colors.white,),),
        backgroundColor: Color(0xFD0D1D5D),
        centerTitle: true,
        leading: Icon(Icons.home,color: Colors.white,),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                final score = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => QuizPage()),
                );
                if (score != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Your Score: $score'),
                    ),
                  );
                  await _loadSavedScore();
                }
              },
              child: Text('Start Quiz'),
            ),
            SizedBox(height: 100,),
            if (_savedScore != null)
              Container(
                height: 80,
                width: 230,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: Color(0xFD0D1D5D),

                ),
                child: Card(
                  elevation: 10,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      'High Score: $_savedScore\nCorrect Answers: $_savedCorrectAnswers',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
