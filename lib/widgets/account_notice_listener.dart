import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../services/account_service.dart';
import 'app_snackbar.dart';

/// Tells the user why this device was signed out of the account when it
/// happened without them asking (revoked from another device, account deleted).
class AccountNoticeListener extends StatefulWidget {
  final Widget child;

  const AccountNoticeListener({super.key, required this.child});

  @override
  State<AccountNoticeListener> createState() => _AccountNoticeListenerState();
}

class _AccountNoticeListenerState extends State<AccountNoticeListener> {
  AccountService? _accountService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final accountService = context.read<AccountService>();
    if (accountService == _accountService) return;
    _accountService?.removeListener(_showNotice);
    _accountService = accountService..addListener(_showNotice);
  }

  @override
  void dispose() {
    _accountService?.removeListener(_showNotice);
    super.dispose();
  }

  void _showNotice() {
    final notice = _accountService?.takeNotice();
    if (notice == null || !mounted) return;
    final l10n = context.l10n;
    final message = switch (notice) {
      AccountNotice.sessionRevoked => l10n.accountNoticeSessionRevoked,
      AccountNotice.sessionRevokedDataKept => l10n.accountNoticeSessionRevokedDataKept,
      AccountNotice.accountDeleted => l10n.accountNoticeAccountDeleted,
    };
    ScaffoldMessenger.of(context).showSnackBar(AppSnackBar.info(context, message));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
