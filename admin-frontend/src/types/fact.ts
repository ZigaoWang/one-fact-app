export interface Fact {
  id?: string;
  content: string;
  source: string;
  category: string;
  tags: string[];
  verified: boolean;
  related_urls: string[];
  metadata: {
    language: string;
    difficulty: string;
    references: string[];
    keywords: string[];
    popularity: number;
    last_served?: string;
    serve_count: number;
  };
  created_at?: string;
  updated_at?: string;
  publish_date?: string;
}

export const CATEGORIES = [
  'Science',
  'Technology',
  'History',
  'Geography',
  'Arts',
  'Culture',
  'Sports',
  'Entertainment',
  'Politics',
  'Business',
  'Education',
  'Health',
  'Environment',
];

export const DIFFICULTIES = ['Easy', 'Medium', 'Hard'];

export const LANGUAGES = ['English', 'Chinese', 'Spanish', 'French', 'German'];
