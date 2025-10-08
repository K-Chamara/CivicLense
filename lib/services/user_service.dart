import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if user is approved
  Future<bool> isUserApproved(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['status'] == 'approved';
      }
      return false;
    } catch (e) {
      print('Error checking user approval status: $e');
      return false;
    }
  }

  /// Get user status
  Future<String?> getUserStatus(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['status'] ?? 'pending';
      }
      return 'pending';
    } catch (e) {
      print('Error getting user status: $e');
      return 'pending';
    }
  }

  /// Get user role
  Future<String?> getUserRole(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['role'];
      }
      return null;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  /// Update user status (approve/reject)
  Future<void> updateUserStatus(String userId, String status) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': _auth.currentUser?.uid,
      });
      print('✅ User status updated to: $status');
    } catch (e) {
      print('❌ Error updating user status: $e');
      throw e;
    }
  }

  /// Update user active status
  Future<void> updateUserActiveStatus(String userId, bool isActive) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid,
      });
      print('✅ User active status updated to: $isActive');
    } catch (e) {
      print('❌ Error updating user active status: $e');
      throw e;
    }
  }

  /// Get all users with pending approval
  Stream<QuerySnapshot> getPendingUsers() {
    return _firestore
        .collection('users')
        .where('status', isEqualTo: 'pending')
        .orderBy('uploadedAt', descending: true)
        .snapshots();
  }

  /// Get all users by status
  Stream<QuerySnapshot> getUsersByStatus(String status) {
    return _firestore
        .collection('users')
        .where('status', isEqualTo: status)
        .orderBy('uploadedAt', descending: true)
        .snapshots();
  }

  /// Get current user data
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          return doc.data() as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      print('Error getting current user data: $e');
      return null;
    }
  }

  /// Check if user needs document upload
  Future<bool> needsDocumentUpload(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final roleData = data['role'];
        
        // Extract role ID and userType from role object or string
        String roleId = 'citizen';
        String userType = 'public';
        if (roleData is String) {
          roleId = roleData.toLowerCase();
        } else if (roleData is Map) {
          roleId = roleData['id']?.toString().toLowerCase() ?? 'citizen';
          userType = roleData['userType']?.toString().toLowerCase() ?? 'public';
        }
        
        print('🔍 needsDocumentUpload: roleId=$roleId, userType=$userType, documents=${data['documents']}');
        
        // If user is citizen, admin, or any government role, they don't need document upload
        if (roleId == 'citizen' || roleId == 'admin' || userType == 'government') {
          print('🔍 needsDocumentUpload: User is citizen/admin/government role, no upload needed');
          return false;
        }
        
        // If no documents uploaded, they need to upload (regardless of status)
        final needsUpload = data['documents'] == null || (data['documents'] as List).isEmpty;
        print('🔍 needsDocumentUpload: needsUpload=$needsUpload');
        return needsUpload;
      }
      print('🔍 needsDocumentUpload: No user document found, needs upload');
      return true; // If no user document exists, they need to upload
    } catch (e) {
      print('Error checking if user needs document upload: $e');
      return true;
    }
  }

  /// Check if user can login (approved or citizen/admin, with limited access for pending users)
  Future<bool> canUserLogin(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final roleData = data['role'];
        final status = data['status'];
        final emailVerified = data['emailVerified'] ?? false;
        
        // Extract role ID from role object or string
        String roleId = 'citizen';
        if (roleData is String) {
          roleId = roleData.toLowerCase();
        } else if (roleData is Map && roleData['id'] != null) {
          roleId = roleData['id'].toString().toLowerCase();
        }
        
        // For users who have uploaded documents but not verified email yet,
        // allow them to login to complete the verification process
        final hasDocuments = data['documents'] != null && (data['documents'] as List).isNotEmpty;
        if (!emailVerified && !hasDocuments) return false;
        
        // Citizens and admins can always login with full access
        if (roleId == 'citizen' || roleId == 'admin') return true;
        
        // ALL users with verified email can login
        // - NGO/Contractor users can login to upload documents
        // - Government users can login with their role
        // - Other users get citizen-level features until approved
        return true;
      }
      return false; // If no user document exists, they can't login
    } catch (e) {
      print('Error checking if user can login: $e');
      return false;
    }
  }
}
