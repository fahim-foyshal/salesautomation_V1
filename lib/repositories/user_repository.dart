import 'package:sqflite/sqflite.dart';

import '../databases/user_dao.dart';
import '../model/user.dart';
      // User model

class UserRepository {
  final UserDao _userDao = UserDao();  // Instance of the UserDao

  // Insert a new user into the database
  Future<int> addUser(Transaction txn,User user) async {
    return await _userDao.saveUserInTransaction(txn,user);
  }

  // Get all users from the database
  Future<List<User>> getUsers() async {
    return await _userDao.getAllUsers();
  }

  // Get a user by their ID
  Future<User?> getUserById(int userId) async {
    return await _userDao.getUserById(userId);
  }

  // Update an existing user's data
  Future<int> updateUser(User user) async {
    return await _userDao.updateUser(user);
  }

  // Delete a user by their ID
  Future<int> deleteUser(int userId) async {
    return await _userDao.deleteUser(userId);
  }

  // Check if a user exists by username
  Future<bool> isUserExist(String username) async {
    return await _userDao.isUserExist(username);
  }
}
