import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Truyện Thần Kỳ';

  @override
  String get homeTab => 'Trang Chủ';

  @override
  String get storiesTab => 'Truyện';

  @override
  String get audioStoriesTab => 'Truyện Audio';

  @override
  String get settingsTab => 'Cài Đặt';

  @override
  String get createStory => 'Tạo Truyện';

  @override
  String get darkMode => 'Chế Độ Tối';

  @override
  String get fontSize => 'Cỡ Chữ';

  @override
  String get language => 'Ngôn Ngữ';

  @override
  String get myStories => 'Truyện Của Tôi';

  @override
  String get sortByDate => 'Sắp Xếp Theo Ngày';

  @override
  String get sortByTheme => 'Sắp Xếp Theo Chủ Đề';

  @override
  String get sortByFavorites => 'Sắp Xếp Theo Yêu Thích';

  @override
  String get deleteStory => 'Xóa Truyện';

  @override
  String get deleteStoryConfirmation => 'Bạn có chắc chắn muốn xóa truyện này không?';

  @override
  String get cancel => 'Hủy';

  @override
  String get delete => 'Xóa';

  @override
  String get retry => 'Thử Lại';

  @override
  String get noStoriesYet => 'Chưa có truyện nào.\nHãy tạo truyện đầu tiên của bạn!';

  @override
  String get justNow => 'Vừa xong';

  @override
  String minutesAgo(int minutes) {
    return '$minutes phút trước';
  }

  @override
  String hoursAgo(int hours) {
    return '$hours giờ trước';
  }

  @override
  String daysAgo(int days) {
    return '$days ngày trước';
  }
}
