import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../search_discover/presentation/pages/search_screen.dart';
import '../../data/datasources/static_people_data.dart';
import '../../domain/entities/person_suggestion.dart';
import '../widgets/person_card.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  late List<PersonSuggestion> _peopleList;

  @override
  void initState() {
    super.initState();
    _peopleList = List.from(StaticPeopleData.suggestions);
  }

  void _removePerson(int index) {
    setState(() {
      _peopleList.removeAt(index);
    });
  }

  void _toggleFollow(int index) {
    setState(() {
      final person = _peopleList[index];
      _peopleList[index] = person.copyWith(
        isFollowed: !person.isFollowed,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.voidBackground,
      appBar: AppBar(
        backgroundColor: AppColors.voidBackground,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Friends',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.search_rounded,
              color: Colors.white,
              size: 26,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        physics: const BouncingScrollPhysics(),
        children: [
          // Headline & Subtitle
          const Text(
            'People You May Know',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Connect with friends and creators.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.outline,
            ),
          ),
          const SizedBox(height: 20),

          // Stacked Cards List
          if (_peopleList.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 60),
              alignment: Alignment.center,
              child: const Text(
                'No more suggestions right now',
                style: TextStyle(color: AppColors.outline, fontSize: 14),
              ),
            )
          else
            ...List.generate(_peopleList.length, (index) {
              final person = _peopleList[index];
              return PersonCard(
                key: ValueKey(person.id),
                person: person,
                onRemove: () => _removePerson(index),
                onFollowToggle: () => _toggleFollow(index),
              );
            }),
        ],
      ),
    );
  }
}
