// This class defines a custom http exception for better error handling 
// It's useful in cases http.delete() which doesnt throw an error report, we can define a custom exception and throw it manually for .catchError() to catch and handle it.

class HttpException implements Exception {
  final String message;

  HttpException(this.message);

  @override
  String toString() {
    return message;
  }
}




// Object is the base class in dart which every object is based on
// All classes invisibly extend Objects
// That's why toString() can be called on any object, although it makes sense only on a few.