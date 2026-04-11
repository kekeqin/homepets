import 'package:flutter_test/flutter_test.dart';
import 'package:homepets/models/user.dart';

void main() {
  test('User model parses JSON correctly', () {
    final user = User.fromJson({
      'id': 1,
      'phone': '13800000001',
      'nickname': '爸爸',
      'role': 'admin',
      'avatar_url': null,
      'family_id': 1,
    });

    expect(user.id, 1);
    expect(user.phone, '13800000001');
    expect(user.nickname, '爸爸');
    expect(user.role, 'admin');
    expect(user.isAdmin, true);
    expect(user.familyId, 1);
  });

  test('User model child role', () {
    final user = User.fromJson({
      'id': 2,
      'phone': null,
      'nickname': '小明',
      'role': 'child',
      'avatar_url': null,
      'family_id': 1,
    });

    expect(user.isAdmin, false);
    expect(user.phone, isNull);
  });
}
