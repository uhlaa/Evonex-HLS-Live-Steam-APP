import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';

import 'package:lottie/lottie.dart';

class CreditsCopyrightScreen extends StatefulWidget {
  final AdvancedDrawerController advancedDrawerController;

  const CreditsCopyrightScreen({
    super.key,
    required this.advancedDrawerController,
  });

  @override
  State<CreditsCopyrightScreen> createState() =>
      _CreditsCopyrightScreenState();
}

class _CreditsCopyrightScreenState
    extends State<CreditsCopyrightScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.tertiary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: theme.colorScheme.onSurface,
            size: 18,
          ),
          onPressed: () =>
              widget.advancedDrawerController.toggleDrawer(),
        ),
        title: Text(
          "About",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),

      /// ✅ SINGLE SCROLL (no Spacer)
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 60),
        child: Column(
          children: [
            SingleChildScrollView(
              
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  /// SHIELD IMAGE
                 Lottie.asset(
  "assets/images/vidplay.json",
  height: 110,
  repeat: true,
  fit: BoxFit.contain,
),
            
                  const SizedBox(height: 70),
            
                  /// CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Credits & Copyright",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
            
                        const _Paragraph(
                          text:
                              "This application does not host, upload, or store any video or streaming content.",
                        ),
                        _divider(),
            
                        const _Paragraph(
                          text:
                              "All live streams are collected from free and publicly available online sources.",
                        ),
                        _divider(),
            
                        const _Paragraph(
                          text:
                              "Credits and copyrights belong to the original content owners and streaming providers.",
                        ),
                       
                      ],
                    ),
                  ),
            
                  const SizedBox(height: 36),
            
                  /// FOOTER
                  
                ],
              ),
            ),
        Spacer(),
            Text(
                "© 2025–26 SPORTEE",
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.inversePrimary,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  text: "Contact: ",
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.inversePrimary,
                  ),
                  children: const [
                    TextSpan(
                      text: "support@sporteeapp.com",
                      style: TextStyle(
                        color:  Color.fromARGB(255, 155, 238, 2),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// ----------------
/// TEXT PARAGRAPH
/// ----------------
class _Paragraph extends StatelessWidget {
  final String text;

  const _Paragraph({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        height: 1.5,
        color: theme.colorScheme.onSurface.withOpacity(0.8),
      ),
    );
  }
}

/// ----------------
/// DIVIDER
/// ----------------
Widget _divider() => const Divider(
      thickness: 0.4,
      height: 20,
    );
