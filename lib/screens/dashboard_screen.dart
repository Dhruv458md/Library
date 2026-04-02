import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_book_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List books = [];
  List filteredBooks = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadBooks();
  }

  // RESPONSIVE GRID COUNT
  int getCrossAxisCount(double width) {
    if (width >= 1200) return 4;
    if (width >= 900) return 3;
    if (width >= 600) return 2;
    return 1;
  }

  // LOAD BOOKS
  Future<void> loadBooks() async {
    final snapshot = await FirebaseFirestore.instance.collection("books").get();

    books = snapshot.docs.map((doc) {
      var data = doc.data();
      data["id"] = doc.id;
      return data;
    }).toList();

    filteredBooks = books;

    setState(() {
      loading = false;
    });
  }

  // DELETE BOOK
  Future<void> deleteBook(int index) async {
    await FirebaseFirestore.instance
        .collection("books")
        .doc(books[index]["id"])
        .delete();

    loadBooks();
  }

  // ISSUE BOOK
  Future<void> toggleIssue(int index) async {
    bool newStatus = !books[index]["issued"];

    await FirebaseFirestore.instance
        .collection("books")
        .doc(books[index]["id"])
        .update({"issued": newStatus});

    loadBooks();
  }

  // LOGOUT
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushReplacementNamed(context, "/login");
  }

  // SEARCH
  void searchBook(String value) {
    setState(() {
      filteredBooks = books.where((book) {
        return book["title"].toString().toLowerCase().contains(
          value.toLowerCase(),
        );
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text("📚 Library Dashboard"),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: logout),
        ],
      ),

      floatingActionButtonLocation: width > 900
          ? FloatingActionButtonLocation.endFloat
          : null,

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, "/addBook");

          loadBooks();
        },
        child: const Icon(Icons.add),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : filteredBooks.isEmpty
          ? const Center(
              child: Text("No Books Available", style: TextStyle(fontSize: 18)),
            )
          : Padding(
              padding: EdgeInsets.all(width < 600 ? 10 : 20),

              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: getCrossAxisCount(width),

                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,

                  childAspectRatio: width < 600 ? 1.8 : 2.2,
                ),

                itemCount: filteredBooks.length,

                itemBuilder: (context, i) {
                  final b = filteredBooks[i];

                  return Container(
                    padding: EdgeInsets.all(width < 600 ? 10 : 15),

                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,

                      borderRadius: BorderRadius.circular(12),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade300,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        // TITLE
                        Text(
                          b["title"],
                          style: TextStyle(
                            fontSize: width < 600 ? 14 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 8),

                        // DETAILS
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Author: ${b["author"] ?? ""}",
                                style: TextStyle(
                                  fontSize: width < 600 ? 12 : 14,
                                ),
                              ),
                              Text(
                                "ISBN: ${b["isbn"] ?? ""}",
                                style: TextStyle(
                                  fontSize: width < 600 ? 12 : 14,
                                ),
                              ),
                              Text(
                                "Quantity: ${b["quantity"] ?? ""}",
                                style: TextStyle(
                                  fontSize: width < 600 ? 12 : 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 5),

                        // ACTIONS
                        Wrap(
                          spacing: 5,
                          runSpacing: 5,

                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),

                              decoration: BoxDecoration(
                                color: b["issued"]
                                    ? Colors.red.shade100
                                    : Colors.green.shade100,

                                borderRadius: BorderRadius.circular(20),
                              ),

                              child: Text(
                                b["issued"] ? "Issued" : "Available",

                                style: TextStyle(
                                  fontSize: width < 600 ? 10 : 12,
                                  color: b["issued"]
                                      ? Colors.red
                                      : Colors.green,
                                ),
                              ),
                            ),

                            IconButton(
                              icon: const Icon(Icons.swap_horiz),
                              iconSize: width < 600 ? 18 : 24,
                              onPressed: () {
                                toggleIssue(i);
                              },
                            ),

                            IconButton(
                              icon: const Icon(Icons.edit),
                              iconSize: width < 600 ? 18 : 24,
                              onPressed: () async {
                                final updated = await Navigator.push(
                                  context,

                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EditBookScreen(book: b),
                                  ),
                                );

                                if (updated != null) {
                                  loadBooks();
                                }
                              },
                            ),

                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              iconSize: width < 600 ? 18 : 24,
                              onPressed: () {
                                deleteBook(i);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
