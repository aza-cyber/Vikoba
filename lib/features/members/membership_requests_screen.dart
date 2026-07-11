import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/models/models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/common.dart';

class MembershipRequestsScreen extends StatelessWidget {
  const MembershipRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final state = context.watch<AppState>();
    final requests = state.pendingMembershipRequests;

    return Scaffold(
      appBar: AppBar(title: Text(locale.t('membership_requests'))),
      body: RefreshIndicator(
        onRefresh: () => state.refresh(),
        child: requests.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  const Icon(Icons.how_to_reg_outlined,
                      size: 56, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  Text(
                    locale.t('no_membership_requests'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: requests.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) =>
                    _MembershipRequestCard(request: requests[i]),
              ),
      ),
    );
  }
}

class _MembershipRequestCard extends StatefulWidget {
  final MembershipRequest request;
  const _MembershipRequestCard({required this.request});

  @override
  State<_MembershipRequestCard> createState() => _MembershipRequestCardState();
}

class _MembershipRequestCardState extends State<_MembershipRequestCard> {
  bool _busy = false;

  Future<void> _act(bool approve) async {
    final locale = context.read<LocaleProvider>();
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final appState = context.read<AppState>();
    final error = approve
        ? await appState.approveMembershipRequest(widget.request.id)
        : await appState.rejectMembershipRequest(widget.request.id);
    if (!mounted) return;
    setState(() => _busy = false);
    messenger.showSnackBar(SnackBar(
      backgroundColor:
          error == null ? AppColors.primary : const Color(0xFFC0392B),
      content: Text(error ??
          (approve
              ? locale.t('membership_approved')
              : locale.t('membership_rejected'))),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final r = widget.request;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              MemberAvatar(initials: r.initials),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 3),
                    Text('${locale.t('phone')}: ${Fmt.phone(r.phone)}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12.5)),
                  ],
                ),
              ),
              StatusChip(
                label: locale.t('pending_approval'),
                color: AppColors.statusPending,
                background: AppColors.statusBorrowerBg,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _detail(locale.t('shares'), '${r.shares}')),
              Expanded(
                  child: _detail(
                      locale.t('requested_on'), Fmt.date(r.requestedOn))),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          if (_busy)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    style:
                        TextButton.styleFrom(foregroundColor: AppColors.fines),
                    onPressed: () => _act(false),
                    icon: const Icon(Icons.close, size: 18),
                    label: Text(locale.t('reject')),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary),
                    onPressed: () => _act(true),
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(locale.t('approve')),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
        ],
      );
}
