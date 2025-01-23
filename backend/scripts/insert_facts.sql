-- Insert facts for multiple days
INSERT INTO facts (content, category, source, active, display_date) VALUES
('The human brain can process images seen for as little as 13 milliseconds, making it one of the fastest image processors known.', 'Science', 'MIT News', true, '2025-01-24'),
('The first computer mouse was made of wood and was invented by Doug Engelbart in the 1960s.', 'Technology', 'Computer History Museum', true, '2025-01-25'),
('The Eiffel Tower can grow up to 6 inches (15 cm) taller during the summer due to thermal expansion of the iron structure.', 'Science', 'Eiffel Tower Official', true, '2025-01-26'),
('Van Gogh only sold one painting during his lifetime, "The Red Vineyard," for 400 francs (about $2000 today).', 'Art', 'Van Gogh Museum', true, '2025-01-27'),
('The first animal to orbit Earth was a dog named Laika, launched by the Soviet Union in 1957.', 'Space', 'NASA', true, '2025-01-28'),
('The Amazon rainforest produces about 20% of the world''s oxygen supply.', 'Nature', 'National Geographic', true, '2025-01-29');

-- Insert related articles for each fact
INSERT INTO related_articles (fact_id, title, url, source, snippet) VALUES
((SELECT id FROM facts WHERE content LIKE '%human brain%'), 'Brain Processing Speed Study', 'https://news.mit.edu/brain-speed', 'MIT News', 'Research reveals the incredible speed of human visual processing.'),
((SELECT id FROM facts WHERE content LIKE '%computer mouse%'), 'The Mother of All Demos', 'https://www.computerhistory.org/mouse', 'Computer History Museum', 'How Doug Engelbart revolutionized human-computer interaction.'),
((SELECT id FROM facts WHERE content LIKE '%Eiffel Tower%'), 'Engineering Marvel: Eiffel Tower', 'https://www.toureiffel.paris/en/engineering', 'Eiffel Tower Official', 'The science behind the Eiffel Tower''s thermal expansion.'),
((SELECT id FROM facts WHERE content LIKE '%Van Gogh%'), 'Van Gogh''s Legacy', 'https://www.vangoghmuseum.nl/red-vineyard', 'Van Gogh Museum', 'The story of Van Gogh''s only painting sold during his lifetime.'),
((SELECT id FROM facts WHERE content LIKE '%Laika%'), 'Space Dogs: The Story of Laika', 'https://www.nasa.gov/laika-history', 'NASA', 'The first animal to orbit Earth and her historic mission.'),
((SELECT id FROM facts WHERE content LIKE '%Amazon%'), 'Amazon Rainforest: Earth''s Lungs', 'https://www.nationalgeographic.com/amazon-oxygen', 'National Geographic', 'How the Amazon rainforest impacts global oxygen levels.');
