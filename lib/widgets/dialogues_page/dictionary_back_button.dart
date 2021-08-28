import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rogers_dictionary/dictionary_navigator/listenable_navigator.dart';

class DictionaryBackButton extends StatelessWidget {
  const DictionaryBackButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ValueListenableBuilder<bool>(
        valueListenable: ListenableNavigator.emptyNotifier,
        builder: (context, isEmpty, _) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 100),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0, .8),
                ),
                child: SlideTransition(
                  child: child,
                  position: Tween<Offset>(
                    begin: const Offset(-1, 0),
                    end: Offset.zero,
                  ).animate(animation),
                ),
              );
            },
            child: Visibility(
              key: ValueKey(!isEmpty),
              visible: !isEmpty,
              child: BackButton(
                onPressed: () => ListenableNavigator.pop(isSystem: false),
              ),
            ),
          );
        },
      ),
    );
  }
}
