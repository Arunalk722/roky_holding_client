import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter/cupertino.dart';

class YNDialogCon {
  static Future<int> ynDialogMessage(
      BuildContext context, {
        required String messageBody,
        required String messageTitle,
        required IconData icon,
        required Color iconColor,
        required String btnDone,
        required String btnClose,
      }) async {
    final completer = Completer<int>();

    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Row(
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 32, // Slightly smaller for Cupertino style
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  messageTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: CupertinoColors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              messageBody,
              style: const TextStyle(
                fontSize: 16,
                color: CupertinoColors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                completer.complete(1); // Done action
                Navigator.pop(context);
              },
              isDefaultAction: true,
              child: Text(
                btnDone,
                style: const TextStyle(
                  color: CupertinoColors.activeGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            CupertinoDialogAction(
              onPressed: () {
                completer.complete(0); // Close action
                Navigator.pop(context);
              },
              isDestructiveAction: true,
              child: Text(
                btnClose,
                style: const TextStyle(
                  color: CupertinoColors.destructiveRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    return completer.future;
  }
}


class OneBtnDialog {
  static Future<bool> oneButtonDialog(
      BuildContext context, {
        required String title,
        required String message,
        required String btnName,
        required IconData icon,
        required Color iconColor,
        required Color btnColor,
      }) async {
    final Completer<bool> completer = Completer<bool>();

    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Row(
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: CupertinoColors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: CupertinoColors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                completer.complete(true);
                Navigator.pop(context);
              },
              isDefaultAction: true,
              child: Text(
                btnName,
                style: TextStyle(
                  color: btnColor, // Button color parameter
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    return completer.future;
  }
}

class ExceptionDialog {
  static void exceptionDialog(
      BuildContext context, {
        required String title,
        required String message,
        required String btnName,
        required IconData icon,
        required Color iconColor,
        required Color btnColor,
      }) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) {
        return LayoutBuilder(
          builder: (context, constraints) {



            double iconSize =32;
            double titleFontSize =18 ;
            double messageFontSize = 18;

            return CupertinoAlertDialog(
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: iconColor,
                    size: iconSize,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: messageFontSize,
                    color: CupertinoColors.black,
                  ),
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  isDefaultAction: true,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: btnColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        btnName,
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

//disable wait dialog
/*class WaitDialog {
  static void showWaitDialog(BuildContext context, {required String message}) {
    showCupertinoDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => false, // Disable back button
          child: CupertinoAlertDialog(
            content: Column(
              children: [
                const SizedBox(height: 16),
                // Custom Activity Indicator
                SizedBox(
                  height: 50,
                  width: 50,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Green progress background (like track)
                      CupertinoActivityIndicator(
                        radius: 20,
                        color: Colors.green.withOpacity(0.3),
                      ),
                      // Yellow spinning progress (active spinner)
                      CupertinoActivityIndicator(
                        radius: 18,
                        color: Colors.yellow,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // "Please wait..." text
                Text(
                  "Please wait...",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.black,
                  ),
                ),
                const SizedBox(height: 8),

                // Custom message text
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void hideDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}*/


class WaitDialog {
  static void showWaitDialog(BuildContext context, {required String message}) {
    showCupertinoDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => false, // Disable back button
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                // Background tap area (now doesn't close the dialog)
                Positioned.fill(
                  child: GestureDetector(

                  ),
                ),
                // Dialog content
                Center(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    child: Stack(
                      children: [
                        CupertinoAlertDialog(
                          content: Column(
                            children: [
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 50,
                                width: 50,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Green progress background
                                    CupertinoActivityIndicator(
                                      radius: 20,
                                      color: Colors.green.withOpacity(0.3),
                                    ),
                                    // Yellow spinning progress
                                    CupertinoActivityIndicator(
                                      radius: 18,
                                      color: Colors.yellow,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                "Please wait...",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: CupertinoColors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                message,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Small cancel button in top-left corner
                        Positioned(
                          top: 0,
                          left: 0,
                          child: GestureDetector(
                            onTap: () => hideDialog(context),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemGrey,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  CupertinoIcons.clear_thick,
                                  size: 12,
                                  color: CupertinoColors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void hideDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}

Future<void> showRequestRefDialog(List<dynamic> dataList, BuildContext context) async {
  if (dataList.isEmpty) return;

  await showCupertinoDialog(
    context: context,
    builder: (context) {
      return Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width > 500 ? 400 : null, // Max width for large screens
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGroupedBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            constraints: const BoxConstraints(maxHeight: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: const [
                    Icon(CupertinoIcons.bell_solid, color: CupertinoColors.activeBlue, size: 24),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pending Requests',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Content
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: dataList.length,
                    itemBuilder: (context, index) {
                      final item = dataList[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: CupertinoColors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: CupertinoColors.systemGrey.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(CupertinoIcons.doc_text, color: CupertinoColors.systemBlue),
                            const SizedBox(width: 10),
                            Expanded(
                              child:
                              Text(
                                'Ref: ${item['req_ref_number'] ?? 'N/A'}|ID: ${item['tbl_user_payment_request_id'] ?? 'N/A'}|Request By:${item['created_by'] ?? 'N/A'}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: CupertinoColors.label,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    borderRadius: BorderRadius.circular(12),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void showTopNotification(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(

    builder: (context) => Positioned(
      bottom: MediaQuery.of(context).viewPadding.bottom +10,
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.deepOrange,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                message,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);

  Future.delayed(Duration(seconds: 3), () {
    entry.remove();
  });
}