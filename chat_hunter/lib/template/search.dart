import 'package:chat_hunter/data/static.dart';
import 'package:flutter/material.dart';

Future<void> searchBottom(context) async {
  TextEditingController search = TextEditingController();
  return await showModalBottomSheet(
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    context: context,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Material(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          color: Theme.of(context).backgroundColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  height: 20,
                ),
                TextFormField(
                  controller: search,
                  decoration: const InputDecoration(
                    hintText: 'Cari Nama ...',
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Material(
                  color: Theme.of(context).primaryColor,
                  child: InkWell(
                    onTap: () {
                      StaticData.searchList(search.text);
                      Navigator.pop(context);
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Center(
                        child: Text(
                          'Cari',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      );
    },
  );
}
