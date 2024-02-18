import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class Course {
  final String name;
  final String code;
  final String department;
  final String year;

  Course({
    required this.name,
    required this.code,
    required this.department,
    required this.year,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      name: json['name'],
      code: json['code'],
      department: json['department'],
      year: json['year'],
    );
  }
}

class CoursesViewModel extends ChangeNotifier {
  late List<Course> _courses;
  late List<Course> _filteredCourses;
  late String _searchQuery;
  late String _selectedDepartment;
  late String _selectedYear;
  late bool _isLoading;

  CoursesViewModel() {
    _courses = [];
    _filteredCourses = [];
    _searchQuery = '';
    _selectedDepartment = '';
    _selectedYear = '';
    _isLoading = false;
    fetchCourses();
  }

  List<Course> get courses => _filteredCourses;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedDepartment => _selectedDepartment;
  String get selectedYear => _selectedYear;

  Future<void> fetchCourses() async {
    _isLoading = true;
    notifyListeners();
    final response =
        await http.get(Uri.parse('https://smsapp.bits-postman-lab.in/courses'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      _courses = data.map((json) => Course.fromJson(json)).toList();
      _filteredCourses = _courses;
    }
    _isLoading = false;
    notifyListeners();
  }

  void filterCourses(String query, String department, String year) {
    _searchQuery = query.toLowerCase();
    _selectedDepartment = department;
    _selectedYear = year;
    _filteredCourses = _courses.where((course) {
      final nameMatches = course.name.toLowerCase().contains(_searchQuery);
      final codeMatches = course.code.toLowerCase().contains(_searchQuery);
      final departmentMatches =
          department.isEmpty || course.department == department;
      final yearMatches = year.isEmpty || course.year == year;
      return (nameMatches || codeMatches) &&
          departmentMatches &&
          yearMatches;
    }).toList();
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Course List',
      theme: ThemeData(
        primaryColor: Colors.blue,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: ChangeNotifierProvider(
        create: (context) => CoursesViewModel(),
        child: CourseListPage(),
      ),
    );
  }
}

class CourseListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Course List'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: CourseSearchDelegate(),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            FilterDropdowns(),
            Expanded(
              child: CourseList(),
            ),
          ],
        ),
      ),
    );
  }
}

class FilterDropdowns extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<CoursesViewModel>(context);
    final departments = Set<String>.from(viewModel.courses.map((course) => course.department)).toList();
    return Container(
      margin: EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          DropdownButton<String>(
            value: viewModel.selectedDepartment,
            onChanged: (value) {
              viewModel.filterCourses(
                viewModel.searchQuery,
                value!,
                viewModel.selectedYear,
              );
            },
            items: <String>[ '','CS', 'Elec.', 'Mech.']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            hint: Text('Select Department'),
          ),
          DropdownButton<String>(
            value: viewModel.selectedYear,
            onChanged: (value) {
              viewModel.filterCourses(
                viewModel.searchQuery,
                viewModel.selectedDepartment,
                value!,
              );
            },
            items: <String>['', '1st', '2nd', '3rd']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            hint: Text('Select Year'),
          ),
        ],
      ),
    );
  }
}

class CourseList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<CoursesViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        if (viewModel.courses.isEmpty) {
          return Center(
            child: Text('No courses available'),
          );
        }
        return ListView.builder(
          itemCount: viewModel.courses.length,
          itemBuilder: (context, index) {
            final course = viewModel.courses[index];
            return ListTile(
              title: Text(course.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Code: ${course.code}'),
                  Text('Department: ${course.department}'),
                  Text('Year: ${course.year}'),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class CourseSearchDelegate extends SearchDelegate<Course> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, SearchResult(course: null) as Course);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final viewModel = Provider.of<CoursesViewModel>(context);
    viewModel.filterCourses(query, viewModel.selectedDepartment, viewModel.selectedYear);
    return CourseList();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }
}

class SearchResult {
  final Course? course;

  SearchResult({required this.course});
}
