import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/utils/hijri_date.dart';
import '../../core/utils/local_clock.dart';
import '../../core/utils/local_numbers.dart';
import '../../l10n/app_localizations.dart';
import '../home_widget/services/home_widget_service.dart';
import 'ifa_district.dart';
import 'ifa_ramadan.dart';

const _green = Color(0xFF0F766E);

/// The district's name in the reader's language.
String ifaDistrictName(BuildContext context, IfaDistrict d) =>
    Localizations.localeOf(context).languageCode == 'bn' ? d.bn : d.en;

/// Turns Islamic Foundation's Ramadan calendar on or off, and picks the
/// district it follows. Answers whether anything changed.
class IfaSheet extends StatefulWidget {
  const IfaSheet({super.key});

  static Future<bool> show(BuildContext context) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const IfaSheet(),
    );
    return changed ?? false;
  }

  @override
  State<IfaSheet> createState() => _IfaSheetState();
}

class _IfaSheetState extends State<IfaSheet> {
  bool _changed = false;
  bool _checking = false;
  String? _checkResult;

  Future<void> _afterChange() async {
    _changed = true;
    if (mounted) setState(() {});
    unawaited(HomeWidgetService().updateWidget());
  }

  Future<void> _check() async {
    final l = L.of(context);
    setState(() {
      _checking = true;
      _checkResult = null;
    });
    final got = await IfaRamadan.refresh(force: true);
    if (!mounted) return;
    setState(() {
      _checking = false;
      _checkResult = got ? l.ifaGot : l.ifaNotYet;
    });
    if (got) await _afterChange();
  }

  Future<void> _pickDistrict() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _DistrictPicker(),
    );
    if (picked == null) return;
    await IfaRamadan.chooseDistrict(picked.isEmpty ? null : picked);
    await _afterChange();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final district = IfaRamadan.district;
    final auto = IfaRamadan.chosenDistrictId == null;
    final year = IfaRamadan.targetYear(DateTime.now());
    final official = IfaRamadan.hasTable(year);
    final first = HijriDate.toGregorian(year, 9, 1);
    final preview = district == null
        ? null
        : IfaRamadan.timesFor(district, first);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.ifaTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.ifaAbout,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                key: const Key('ifa-enabled'),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l.ifaUse,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                value: IfaRamadan.enabled,
                activeThumbColor: _green,
                onChanged: (v) async {
                  await IfaRamadan.setEnabled(v);
                  await _afterChange();
                  if (v && !official) unawaited(IfaRamadan.refresh());
                },
              ),
              const Divider(height: 8),
              ListTile(
                key: const Key('ifa-district'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.place_rounded, color: _green),
                title: Text(l.ifaDistrict),
                subtitle: Text(
                  district == null
                      ? l.ifaNoDistrict
                      : auto
                      ? l.ifaFromLocation(ifaDistrictName(context, district))
                      : ifaDistrictName(context, district),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _pickDistrict,
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: official
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          official
                              ? Icons.verified_rounded
                              : Icons.calculate_rounded,
                          size: 18,
                          color: official ? _green : const Color(0xFFB45309),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            official
                                ? l.ifaOfficial(N.plain(year))
                                : l.ifaComputed(N.plain(year)),
                            key: const Key('ifa-status'),
                            style: const TextStyle(fontSize: 13, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                    if (preview != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        l.ifaFirstDay(DateFormat.yMMMEd().format(first)),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _time(l.ramadanSahriEnds, preview.sahri),
                          _time(l.ifaFajrAzan, preview.fajr),
                          _time(l.ramadanIftar, preview.iftar),
                        ],
                      ),
                    ],
                    if (!official) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            key: const Key('ifa-check'),
                            onPressed: _checking ? null : _check,
                            icon: _checking
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.refresh_rounded, size: 18),
                            label: Text(_checking ? l.ifaChecking : l.ifaCheck),
                          ),
                          if (_checkResult != null) ...[
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                _checkResult!,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l.ifaRule,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _time(String label, DateTime t) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            Clock.h12(t),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

/// All 64 districts by division, with a search box. Pops the chosen id, or
/// '' for "follow my location".
class _DistrictPicker extends StatefulWidget {
  const _DistrictPicker();

  @override
  State<_DistrictPicker> createState() => _DistrictPickerState();
}

class _DistrictPickerState extends State<_DistrictPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final bn = Localizations.localeOf(context).languageCode == 'bn';
    final q = _query.trim().toLowerCase();
    final matches = [
      for (final d in ifaDistricts)
        if (q.isEmpty ||
            d.en.toLowerCase().contains(q) ||
            d.bn.contains(_query.trim()))
          d,
    ];
    final current = IfaRamadan.chosenDistrictId;
    String division(String id) => bn
        ? IfaDistrict.divisions[id]!
        : '${id[0].toUpperCase()}${id.substring(1)}';

    final children = <Widget>[];
    if (q.isEmpty) {
      children.add(
        ListTile(
          key: const Key('ifa-district-auto'),
          leading: const Icon(Icons.my_location_rounded, color: _green),
          title: Text(l.ifaAuto),
          subtitle: IfaDistrict.byId(IfaRamadan.autoDistrictId) == null
              ? null
              : Text(
                  ifaDistrictName(
                    context,
                    IfaDistrict.byId(IfaRamadan.autoDistrictId)!,
                  ),
                ),
          trailing: current == null
              ? const Icon(Icons.check_rounded, color: _green)
              : null,
          onTap: () => Navigator.pop(context, ''),
        ),
      );
    }
    String? lastDivision;
    for (final d in matches) {
      if (d.division != lastDivision) {
        lastDivision = d.division;
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              division(d.division),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        );
      }
      children.add(
        ListTile(
          key: Key('ifa-district-${d.id}'),
          dense: true,
          title: Text(bn ? d.bn : d.en),
          trailing: current == d.id
              ? const Icon(Icons.check_rounded, color: _green)
              : null,
          onTap: () => Navigator.pop(context, d.id),
        ),
      );
    }

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              key: const Key('ifa-district-search'),
              decoration: InputDecoration(
                hintText: l.ifaSearch,
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(child: ListView(children: children)),
        ],
      ),
    );
  }
}
