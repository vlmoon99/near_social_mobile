import 'dart:html' as html;

bool get isPWA {
  if (html.window.matchMedia('(display-mode: standalone)').matches) {
    return true;
  } else {
    return false;
  }
}
