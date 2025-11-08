import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const FlashCardApp());
}

class FlashCard {
  final String id;
  final String question;
  final String answer;
  bool isExpanded;

  FlashCard({
    required this.question,
    required this.answer,
    this.isExpanded = false,
    String? id,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  FlashCard copyWith({bool? isExpanded}) {
    return FlashCard(
      question: question,
      answer: answer,
      id: id,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }
}

class FlashCardApp extends StatefulWidget {
  const FlashCardApp({super.key});

  @override
  State<FlashCardApp> createState() => _FlashCardAppState();
}

class _FlashCardAppState extends State<FlashCardApp> {
  final GlobalKey<SliverAnimatedListState> _animatedListKey =
  GlobalKey<SliverAnimatedListState>();

  final List<FlashCard> _flashcards = [];
  final List<FlashCard> _learnedCards = [];
  bool _isRefreshing = false;

  // keep a copy of the initial set so "reset" can restore it
  late final List<FlashCard> _initialSet;

  @override
  void initState() {
    super.initState();
    _initialSet = _makeInitialFlashcards();
    _loadInitialFlashcards();
  }

  List<FlashCard> _makeInitialFlashcards() {
    return [
      FlashCard(
        question: "What is Flutter?",
        answer:
        "Flutter is Google's UI toolkit for building natively compiled applications for mobile, web, and desktop from a single codebase.",
      ),
      FlashCard(
        question: "What is a Widget in Flutter?",
        answer:
        "A Widget is the basic building block of a Flutter app's user interface. Everything in Flutter is a widget.",
      ),
      FlashCard(
        question: "What is the difference between Stateless and Stateful Widget?",
        answer:
        "Stateless widgets are immutable and cannot change, while Stateful widgets can change their state during the widget's lifetime.",
      ),
      FlashCard(
        question: "What is BuildContext?",
        answer:
        "BuildContext is a handle to the location of a widget in the widget tree. It's used to access theme data, navigate, and find other widgets.",
      ),
      FlashCard(
        question: "What is the purpose of setState()?",
        answer:
        "setState() notifies the framework that the internal state of the widget has changed, which triggers a rebuild of the widget and its descendants.",
      ),
    ];
  }

  void _loadInitialFlashcards() {
    setState(() {
      _flashcards.clear();
      _flashcards.addAll(_initialSet.map((c) =>
          FlashCard(question: c.question, answer: c.answer, isExpanded: false)));
      _learnedCards.clear();
    });
  }

  Future<void> _refreshFlashcards() async {
    setState(() {
      _isRefreshing = true;
    });

    // simulate network/test delay
    await Future.delayed(const Duration(seconds: 1));

    final newFlashcards = [
      FlashCard(
        question: "What is Dart?",
        answer:
        "Dart is the programming language used by Flutter. It's optimized for building user interfaces.",
      ),
      FlashCard(
        question: "What is Hot Reload?",
        answer:
        "Hot Reload allows developers to quickly see changes in their code without restarting the app, maintaining the app state.",
      ),
      FlashCard(
        question: "What is a Key in Flutter?",
        answer:
        "A Key is an identifier for Widgets, Elements and SemanticsNodes. It helps Flutter identify when widgets change.",
      ),
      FlashCard(
        question: "What is the widget tree?",
        answer: "The widget tree is the hierarchy of widgets that build your app's user interface.",
      ),
      FlashCard(
        question: "What is the element tree?",
        answer:
        "The element tree is the instantiation of the widget tree that manages the lifecycle and state of widgets.",
      ),
    ];

    setState(() {
      _flashcards.clear();
      _flashcards.addAll(newFlashcards);
      _learnedCards.clear();
      _isRefreshing = false;
    });
  }

  void _addNewFlashcard() {
    final newCard = FlashCard(
      question: "New Question ${_flashcards.length + 1}",
      answer: "This is the answer for the new question. Customize as needed.",
    );

    setState(() {
      _flashcards.insert(0, newCard);
      // animate insertion at 0
      _animatedListKey.currentState?.insertItem(0,
          duration: const Duration(milliseconds: 400));
    });
  }

  void _shuffleFlashcards() {
    setState(() {
      _flashcards.shuffle(Random());
    });
  }

  void _resetToInitial() {
    setState(() {
      // clear current and restore initial set (not animated)
      _flashcards.clear();
      _flashcards.addAll(_initialSet
          .map((c) => FlashCard(question: c.question, answer: c.answer)));
      _learnedCards.clear();
    });
  }

  void _toggleExpansion(int index) {
    if (index < 0 || index >= _flashcards.length) return;
    setState(() {
      _flashcards[index].isExpanded = !_flashcards[index].isExpanded;
    });
  }

  // When a card is marked learned (by swipe),
  // remove it from the list and give an Undo snackbar that reinserts it.
  void _markAsLearnedById(String id, BuildContext scaffoldContext) {
    final currentIndex = _flashcards.indexWhere((c) => c.id == id);
    if (currentIndex == -1) return;
    final card = _flashcards[currentIndex];

    setState(() {
      _flashcards.removeAt(currentIndex);
      _learnedCards.add(card);
    });

    // show snackbar with undo
    final messenger = ScaffoldMessenger.of(scaffoldContext);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        content: Text('Marked "${card.question}" as learned.'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            // undo: remove from learned and reinsert at same index with animation
            setState(() {
              _learnedCards.removeWhere((c) => c.id == card.id);
              final insertIndex = currentIndex.clamp(0, _flashcards.length);
              _flashcards.insert(insertIndex, card);
              _animatedListKey.currentState?.insertItem(insertIndex,
                  duration: const Duration(milliseconds: 350));
            });
          },
        ),
      ),
    );
  }

  Widget _buildFlashcardItem(
      BuildContext context, int index, Animation<double> animation) {
    // Defensive guard (can happen during animations)
    if (index < 0 || index >= _flashcards.length) {
      return const SizedBox.shrink();
    }

    final card = _flashcards[index];

    // Wrap with SizeTransition so SliverAnimatedList removal/insert animations look smooth
    return SizeTransition(
      sizeFactor: animation,
      axisAlignment: 0.0,
      child: Dismissible(
        key: Key(card.id),
        direction: DismissDirection.endToStart,
        background: Container(
          color: Colors.green,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: const [
              Text(
                'MARK LEARNED',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.check_circle, color: Colors.white, size: 26),
            ],
          ),
        ),
        confirmDismiss: (direction) async {
          // quick confirm dialog
          return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Mark as learned?'),
              content: const Text(
                  'This will remove the card from the current study list.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Mark Learned')),
              ],
            ),
          ) ??
              false;
        },
        onDismissed: (direction) {
          // Dismissible already animated the swipe out.
          // Now update underlying data and show undo.
          _markAsLearnedById(card.id, context);
        },
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 3,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            key: Key('tile_${card.id}'),
            initiallyExpanded: card.isExpanded,
            leading: CircleAvatar(
              backgroundColor:
              Theme.of(context).colorScheme.primary.withOpacity(0.12),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              card.question,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            trailing: Icon(
              card.isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Theme.of(context).colorScheme.primary,
            ),
            children: [
              Container(
                width: double.infinity,
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  border: Border(
                    top: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                ),
                child: Text(
                  card.answer,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
            onExpansionChanged: (_) => _toggleExpansion(index),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = _flashcards.length + _learnedCards.length;
    final learnedCount = _learnedCards.length;
    final progress = totalCount > 0 ? learnedCount / totalCount : 0.0;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flashcard Learning App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: _addNewFlashcard,
          child: const Icon(Icons.add),
        ),
        body: RefreshIndicator(
          onRefresh: _refreshFlashcards,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 150,
                pinned: true,
                actions: [
                  IconButton(
                    tooltip: 'Shuffle',
                    onPressed: _shuffleFlashcards,
                    icon: const Icon(Icons.shuffle),
                  ),
                  IconButton(
                    tooltip: 'Reset',
                    onPressed: _resetToInitial,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding:
                  const EdgeInsetsDirectional.only(start: 16, bottom: 12),
                  title: Text(
                    '$learnedCount of $totalCount Learned',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primaryContainer,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 10,
                              backgroundColor: Colors.white24,
                              valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(progress * 100).toStringAsFixed(1)}% Complete',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (_isRefreshing) const LinearProgressIndicator(),
                      const SizedBox(height: 8),
                      Text(
                        'Swipe left to mark learned • Tap to reveal answer • Pull to refresh',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // If no flashcards show friendly empty state
              if (_flashcards.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.celebration,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'All flashcards learned! 🎉',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Pull down to refresh for new questions',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _refreshFlashcards,
                          icon: const Icon(Icons.restart_alt),
                          label: const Text('Get New Questions'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverAnimatedList(
                  key: _animatedListKey,
                  initialItemCount: _flashcards.length,
                  itemBuilder: (context, index, animation) =>
                      _buildFlashcardItem(context, index, animation),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
