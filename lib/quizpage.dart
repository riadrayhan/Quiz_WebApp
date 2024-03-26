import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart'as http;
import 'package:shared_preferences/shared_preferences.dart';

class QuizPage extends StatefulWidget {
  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<dynamic> _questions = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _showAnswer = false;
  bool _timerEnded = false;
  int _progressValue = 0;
  late Timer _timer;
  int _score = 0;
  int _correctAnswers = 0;

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _fetchQuestions() async {
    final response = await http.get(
      Uri.parse("https://herosapp.nyc3.digitaloceanspaces.com/quiz.json"),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body)['questions'];
      setState(() {
        _questions = data;
        _isLoading = false;
      });
    } else {
      throw Exception('Failed to load questions');
    }
  }

  void _startTimer() {
    const oneSec = const Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
          (Timer timer) {
        if (_progressValue == 10) {
          timer.cancel();
          setState(() {
            _timerEnded = true;
          });
          _nextQuestion();
        } else {
          setState(() {
            _progressValue++;
          });
        }
      },
    );
  }

  void _nextQuestion() {
    _timer.cancel();
    setState(() {
      if (_currentIndex < _questions.length - 1) {
        _currentIndex++;
        _progressValue = 0;
        _timerEnded = false;
        _showAnswer = false;
        _startTimer();
      } else {
        // End of questions
        _showQuizEndDialog();
      }
    });
  }

  Future<void> _showQuizEndDialog() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? savedScore = prefs.getInt('score') ?? 0;
    int? savedCorrectAnswers = prefs.getInt('correctAnswers') ?? 0;

    if (_score > savedScore!) {
      await prefs.setInt('score', _score);
      await prefs.setInt('correctAnswers', _correctAnswers);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Quiz Finished'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('You have completed the quiz!'),
              SizedBox(height: 10),
              Text('Score: $_score'),
              Text('Correct Answers: $_correctAnswers/${_questions.length}'),
              if (_score > savedScore!)
                Text(
                  'New High Score! 🎉',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, _score);
                Navigator.pop(context); // Pop quiz page and return to main menu
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Questions Paper',style: TextStyle(fontWeight: FontWeight.w400,color: Colors.white,),),
        backgroundColor: Color(0xFD0D1D5D),
        centerTitle: true,
        leading: Icon(Icons.question_answer,color: Colors.white,),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: _progressValue / 10,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                  _timerEnded ? Colors.red : Colors.blue),
            ),
            SizedBox(height: 20.0),
            Text(
              'Question ${_currentIndex + 1}/${_questions.length}',
              style: TextStyle(fontSize: 20.0),
            ),
            SizedBox(height: 10.0),
            Text(
              _questions[_currentIndex]['question'],
              style: TextStyle(fontSize: 24.0),
            ),
            if (_questions[_currentIndex]['questionImageUrl'] != null)
              Image.network(
                _questions[_currentIndex]['questionImageUrl'],
                height: 200,
                width: 200,
              ),
            SizedBox(height: 20.0),
            ...(_questions[_currentIndex]['answers']
            as Map<String, dynamic>)
                .entries
                .map((entry) {
              final option = entry.key;
              final answer = entry.value;
              return ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showAnswer = true;
                    if (option ==
                        _questions[_currentIndex]['correctAnswer']) {
                      _score +=
                      _questions[_currentIndex]['score'] as int;
                      _correctAnswers++;
                    }
                  });
                  _timer.cancel();
                  Future.delayed(Duration(seconds: 2), () {
                    _nextQuestion();
                  });
                },
                child: Text(
                  '$option. $answer',
                  style: TextStyle(
                      color: _showAnswer &&
                          option ==
                              _questions[_currentIndex]['correctAnswer']
                          ? Colors.green
                          : Colors.black),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}