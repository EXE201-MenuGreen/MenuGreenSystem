import 'package:flutter/material.dart';

/// Extension để hiển thị SnackBar an toàn khi bàn phím xuất hiện
extension KeyboardAwareSnackBar on BuildContext {
  /// Hiển thị SnackBar với vị trí tự động điều chỉnh theo bàn phím
  void showKeyboardAwareSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
    Color? backgroundColor,
    Color? textColor,
    SnackBarAction? action,
    SnackBarBehavior behavior = SnackBarBehavior.floating,
  }) {
    final isKeyboardVisible = MediaQuery.of(this).viewInsets.bottom > 0;
    
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: textColor ?? Colors.white),
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        action: action,
        // Khi bàn phím xuất hiện, đặt margin-bottom để SnackBar nằm trên bàn phím
        margin: isKeyboardVisible
            ? EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(this).viewInsets.bottom + 16,
              )
            : const EdgeInsets.only(left: 16, right: 16, bottom: 24),
        behavior: behavior,
      ),
    );
  }

  /// Hiển thị SnackBar thành công
  void showSuccessSnackBar(String message) {
    showKeyboardAwareSnackBar(
      message,
      backgroundColor: const Color(0xFF2E7D32),
    );
  }

  /// Hiển thị SnackBar lỗi
  void showErrorSnackBar(String message) {
    showKeyboardAwareSnackBar(
      message,
      backgroundColor: const Color(0xFFC62828),
    );
  }

  /// Hiển thị SnackBar cảnh báo
  void showWarningSnackBar(String message) {
    showKeyboardAwareSnackBar(
      message,
      backgroundColor: const Color(0xFFED6C02),
    );
  }
}

/// Widget wrapper tự động điều chỉnh padding khi bàn phím xuất hiện
/// Dùng cho các màn hình có form nhập liệu
class KeyboardAwareScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final EdgeInsetsDirectional? padding;

  const KeyboardAwareScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      body: SafeArea(
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: body,
        ),
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

/// Widget wrapper cho body có form nhập liệu - tự động scroll khi focus vào text field
class KeyboardAwareScrollView extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;

  const KeyboardAwareScrollView({
    super.key,
    required this.child,
    this.padding,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          controller: controller,
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: child,
          ),
        );
      },
    );
  }
}

/// Stateful version với auto-scroll khi bàn phím xuất hiện
class StatefulKeyboardAwareScrollView extends StatefulWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;

  const StatefulKeyboardAwareScrollView({
    super.key,
    required this.children,
    this.padding,
    this.controller,
  });

  @override
  State<StatefulKeyboardAwareScrollView> createState() =>
      _StatefulKeyboardAwareScrollViewState();
}

class _StatefulKeyboardAwareScrollViewState
    extends State<StatefulKeyboardAwareScrollView> {
  late final ScrollController _scrollController;
  final FocusNode _focusNode = FocusNode();
  bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && _isKeyboardVisible) {
      // Scroll đến vị trí focus sau một tick để đảm bảo layout đã hoàn tất
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    _isKeyboardVisible = bottomInset > 0;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Không cần xử lý scroll notification
        return false;
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: widget.padding,
        child: Column(
          children: widget.children,
        ),
      ),
    );
  }
}
