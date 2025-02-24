import 'package:alice/model/alice_menu_item.dart';
import 'package:alice/helper/alice_alert_helper.dart';
import 'package:alice/model/alice_sort_option.dart';
import 'package:alice/ui/page/alice_call_details_screen.dart';
import 'package:alice/core/alice_core.dart';
import 'package:alice/model/alice_http_call.dart';
import 'package:alice/utils/alice_constants.dart';
import 'package:alice/ui/widget/alice_call_list_item_widget.dart';
import 'package:flutter/material.dart';

import 'alice_stats_screen.dart';

class AliceCallsListScreen extends StatefulWidget {
  final AliceCore _aliceCore;

  const AliceCallsListScreen(this._aliceCore);

  @override
  _AliceCallsListScreenState createState() => _AliceCallsListScreenState();
}

class _AliceCallsListScreenState extends State<AliceCallsListScreen> {
  AliceCore get aliceCore => widget._aliceCore;
  bool _searchEnabled = false;
  final TextEditingController _queryTextEditingController =
      TextEditingController();
  final List<AliceMenuItem> _menuItems = [];
  AliceSortOption? _sortOption = AliceSortOption.time;
  bool _sortAscending = false;

  _AliceCallsListScreenState() {
    _menuItems.add(AliceMenuItem("Sort", Icons.sort));
    _menuItems.add(AliceMenuItem("Delete", Icons.delete));
    _menuItems.add(AliceMenuItem("Stats", Icons.insert_chart));
    _menuItems.add(AliceMenuItem("Save", Icons.save));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          widget._aliceCore.directionality ?? Directionality.of(context),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          title: _searchEnabled ? _buildSearchField() : _buildTitleWidget(),
          actions: [
            _buildSearchButton(),
            _buildMenuButton(),
          ],
        ),
        body: _buildCallsListWrapper(),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _queryTextEditingController.dispose();
  }

  Widget _buildSearchButton() {
    return IconButton(
      icon: const Icon(Icons.search),
      onPressed: _onSearchClicked,
    );
  }

  void _onSearchClicked() {
    setState(() {
      _searchEnabled = !_searchEnabled;
      if (!_searchEnabled) {
        _queryTextEditingController.text = "";
      }
    });
  }

  Widget _buildMenuButton() {
    return PopupMenuButton<AliceMenuItem>(
      onSelected: (AliceMenuItem item) => _onMenuItemSelected(item),
      itemBuilder: (BuildContext context) {
        return _menuItems.map((AliceMenuItem item) {
          return PopupMenuItem<AliceMenuItem>(
            value: item,
            child: Row(
              children: [
                Icon(
                  item.iconData,
                  color: AliceConstants.lightRed,
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 10),
                ),
                Text(item.title)
              ],
            ),
          );
        }).toList();
      },
    );
  }

  Widget _buildTitleWidget() {
    return const Text("Alice - Inspector");
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _queryTextEditingController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: "Search http request...",
        hintStyle: TextStyle(fontSize: 16.0, color: AliceConstants.grey),
        border: InputBorder.none,
      ),
      style: const TextStyle(fontSize: 16.0),
      onChanged: _updateSearchQuery,
    );
  }

  void _onMenuItemSelected(AliceMenuItem menuItem) {
    if (menuItem.title == "Sort") {
      _showSortDialog();
    }
    if (menuItem.title == "Delete") {
      _showRemoveDialog();
    }
    if (menuItem.title == "Stats") {
      _showStatsScreen();
    }
    if (menuItem.title == "Save") {
      _saveToFile();
    }
  }

  Widget _buildCallsListWrapper() {
    return StreamBuilder<List<AliceHttpCall>>(
      stream: aliceCore.callsSubject,
      builder: (context, snapshot) {
        List<AliceHttpCall> calls = snapshot.data ?? [];
        final String query = _queryTextEditingController.text.trim();
        if (query.isNotEmpty) {
          calls = calls
              .where(
                (call) =>
                    call.endpoint.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
        }
        if (calls.isNotEmpty) {
          return _buildCallsListWidget(calls);
        } else {
          return _buildEmptyWidget();
        }
      },
    );
  }

  Widget _buildEmptyWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: AliceConstants.orange,
            ),
            const SizedBox(height: 6),
            const Text(
              "There are no calls to show",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "• Check if you send any http request",
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                Text(
                  "• Check your Alice configuration",
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                Text(
                  "• Check search filters",
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCallsListWidget(List<AliceHttpCall> calls) {
    final List<AliceHttpCall> callsSorted = List.of(calls);
    switch (_sortOption) {
      case AliceSortOption.time:
        if (_sortAscending) {
          callsSorted.sort(
            (call1, call2) => call1.createdTime.compareTo(call2.createdTime),
          );
        } else {
          callsSorted.sort(
            (call1, call2) => call2.createdTime.compareTo(call1.createdTime),
          );
        }
        break;
      case AliceSortOption.responseTime:
        if (_sortAscending) {
          callsSorted.sort();
          callsSorted.sort(
            (call1, call2) =>
                call1.response?.time.compareTo(call2.response!.time) ?? -1,
          );
        } else {
          callsSorted.sort(
            (call1, call2) =>
                call2.response?.time.compareTo(call1.response!.time) ?? -1,
          );
        }
        break;
      case AliceSortOption.responseCode:
        if (_sortAscending) {
          callsSorted.sort(
            (call1, call2) =>
                call1.response?.status?.compareTo(call2.response!.status!) ??
                -1,
          );
        } else {
          callsSorted.sort(
            (call1, call2) =>
                call2.response?.status?.compareTo(call1.response!.status!) ??
                -1,
          );
        }
        break;
      case AliceSortOption.responseSize:
        if (_sortAscending) {
          callsSorted.sort(
            (call1, call2) =>
                call1.response?.size.compareTo(call2.response!.size) ?? -1,
          );
        } else {
          callsSorted.sort(
            (call1, call2) =>
                call2.response?.size.compareTo(call1.response!.size) ?? -1,
          );
        }
        break;
      case AliceSortOption.endpoint:
        if (_sortAscending) {
          callsSorted
              .sort((call1, call2) => call1.endpoint.compareTo(call2.endpoint));
        } else {
          callsSorted
              .sort((call1, call2) => call2.endpoint.compareTo(call1.endpoint));
        }
        break;
      default:
        break;
    }

    return ListView.builder(
      itemCount: callsSorted.length,
      itemBuilder: (context, index) {
        return AliceCallListItemWidget(callsSorted[index], _onListItemClicked);
      },
    );
  }

  void _onListItemClicked(AliceHttpCall call) {
    Navigator.push<void>(
      widget._aliceCore.getContext()!,
      MaterialPageRoute(
        builder: (context) => AliceCallDetailsScreen(call, widget._aliceCore),
      ),
    );
  }

  void _showRemoveDialog() {
    AliceAlertHelper.showAlert(
      context,
      "Delete calls",
      "Do you want to delete http calls?",
      firstButtonTitle: "No",
      firstButtonAction: () => <String, dynamic>{},
      secondButtonTitle: "Yes",
      secondButtonAction: () => _removeCalls(),
    );
  }

  void _removeCalls() {
    aliceCore.removeCalls();
  }

  void _showStatsScreen() {
    Navigator.push<void>(
      aliceCore.getContext()!,
      MaterialPageRoute(
        builder: (context) => AliceStatsScreen(widget._aliceCore),
      ),
    );
  }

  void _saveToFile() async {
    aliceCore.saveHttpRequests(context);
  }

  void _updateSearchQuery(String query) {
    setState(() {});
  }

  void _showSortDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext buildContext) {
        return Theme(
          data: ThemeData(
            brightness: Brightness.light,
          ),
          child: AlertDialog(
            title: const Text("Select filter"),
            content: StatefulBuilder(
              builder: (context, setState) {
                return Wrap(
                  children: [
                    ...AliceSortOption.values
                        .map(
                          (AliceSortOption sortOption) =>
                              RadioListTile<AliceSortOption>(
                            title: Text(sortOption.name),
                            value: sortOption,
                            groupValue: _sortOption,
                            onChanged: (AliceSortOption? value) {
                              setState(() {
                                _sortOption = value;
                              });
                            },
                          ),
                        )
                        .toList(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Descending"),
                        Switch(
                          value: _sortAscending,
                          onChanged: (value) {
                            setState(() {
                              _sortAscending = value;
                            });
                          },
                          activeTrackColor: Colors.grey,
                          activeColor: Colors.white,
                        ),
                        const Text("Ascending")
                      ],
                    )
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  sortCalls();
                },
                child: const Text("Use filter"),
              ),
            ],
          ),
        );
      },
    );
  }

  void sortCalls() {
    setState(() {});
  }
}
