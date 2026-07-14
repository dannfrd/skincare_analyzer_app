import 'package:flutter/material.dart';

/// Custom PageTransitionsBuilder for ThemeData.pageTransitionsTheme
/// Gives a cinematic, highly noticeable, buttery-smooth Cupertino + Parallax Slide on all platforms.
class SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const SmoothPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Ultra-smooth spring-like cubic curve (similar to iOS / Modern Android 14)
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: const Cubic(0.16, 1.0, 0.3, 1.0),
      reverseCurve: const Cubic(0.2, 0.8, 0.2, 1.0),
    );

    final secondaryCurvedAnimation = CurvedAnimation(
      parent: secondaryAnimation,
      curve: const Cubic(0.16, 1.0, 0.3, 1.0),
      reverseCurve: const Cubic(0.2, 0.8, 0.2, 1.0),
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0), // Slides in clearly from right edge
        end: Offset.zero,
      ).animate(curvedAnimation),
      child: FadeTransition(
        opacity: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(curvedAnimation),
        // Secondary transition for when another screen pushes on top of this screen
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(-0.25, 0.0), // Parallax shift to left
          ).animate(secondaryCurvedAnimation),
          child: FadeTransition(
            opacity: Tween<double>(
              begin: 1.0,
              end: 0.6, // Darken background page for 3D depth
            ).animate(secondaryCurvedAnimation),
            child: ScaleTransition(
              scale: Tween<double>(
                begin: 1.0,
                end: 0.93, // Subtle scale down of background page
              ).animate(secondaryCurvedAnimation),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom PageRouteBuilder with unmistakable 450ms duration and Cupertino parallax slide.
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;

  SmoothPageRoute({
    required this.builder,
    super.settings,
  }) : super(
          transitionDuration: const Duration(milliseconds: 450),
          reverseTransitionDuration: const Duration(milliseconds: 360),
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: const Cubic(0.16, 1.0, 0.3, 1.0),
              reverseCurve: const Cubic(0.2, 0.8, 0.2, 1.0),
            );

            final secondaryCurvedAnimation = CurvedAnimation(
              parent: secondaryAnimation,
              curve: const Cubic(0.16, 1.0, 0.3, 1.0),
              reverseCurve: const Cubic(0.2, 0.8, 0.2, 1.0),
            );

            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0), // Slides in clearly from right edge
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: FadeTransition(
                opacity: Tween<double>(
                  begin: 0.0,
                  end: 1.0,
                ).animate(curvedAnimation),
                // Secondary transition for when another screen pushes on top of this screen
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset.zero,
                    end: const Offset(-0.25, 0.0), // Parallax shift to left
                  ).animate(secondaryCurvedAnimation),
                  child: FadeTransition(
                    opacity: Tween<double>(
                      begin: 1.0,
                      end: 0.6, // Darken background page for 3D depth
                    ).animate(secondaryCurvedAnimation),
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 1.0,
                        end: 0.93, // Subtle scale down of background page
                      ).animate(secondaryCurvedAnimation),
                      child: child,
                    ),
                  ),
                ),
              ),
            );
          },
        );
}
