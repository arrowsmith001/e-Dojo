# edojo

A multi-platform app built in Flutter for fighting game enthusiasts. It provides an online platform where users can challenge each other to games, record outcomes, and contribute towards a data pool to gain insights on the game and their individual performance.

Currently uses Firebase for all its online functionality, though in theory any implementation of the 'NetworkServices' class could allow for alternative approaches.

Data model management is done through BLoC-inspired stream and sink system which interact with a centralised data center.