import 'dart:async';
import 'package:flutter/material.dart';

class InactivityLogout extends StatefulWidget {
	final Widget child;
	final Duration timeout;
	final VoidCallback onTimeout;

	const InactivityLogout({super.key, required this.child, required this.timeout, required this.onTimeout});

	@override
	State<InactivityLogout> createState() => _InactivityLogoutState();
}

class _InactivityLogoutState extends State<InactivityLogout> with WidgetsBindingObserver {
	Timer? _timer;

	@override
	void initState() {
		super.initState();
		WidgetsBinding.instance.addObserver(this);
		_startTimer();
	}

	@override
	void dispose() {
		WidgetsBinding.instance.removeObserver(this);
		_timer?.cancel();
		super.dispose();
	}

	@override
	void didChangeAppLifecycleState(AppLifecycleState state) {
		if (state == AppLifecycleState.resumed) {
			_resetTimer();
		} else if (state == AppLifecycleState.paused) {
			_timer?.cancel();
		}
	}

	void _startTimer() {
		_timer?.cancel();
		_timer = Timer(widget.timeout, widget.onTimeout);
	}

	void _resetTimer() {
		_startTimer();
	}

	void _handleUserInteraction([_]) {
		_resetTimer();
	}

	@override
	Widget build(BuildContext context) {
		return Listener(
			onPointerDown: _handleUserInteraction,
			onPointerMove: _handleUserInteraction,
			onPointerUp: _handleUserInteraction,
			child: widget.child,
		);
	}
}





