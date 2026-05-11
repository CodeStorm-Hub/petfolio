// PetFolio data — pets, species, breeds. Window-scoped for cross-file React access.

const TOKENS = {
  // Light mode
  blue50:   '#EEF4FF',
  blue100:  '#D6E4FF',
  blue200:  '#AEC6FF',
  blue400:  '#4B7DFA',
  blue500:  '#2563EB',
  blue600:  '#1D4FCC',
  blue700:  '#173FA3',
  blue900:  '#091B47',

  sunset:   '#F4A261',
  sunsetT:  '#FDEBD6',
  coral:    '#E76F51',
  coralT:   '#FBDFD5',
  meadow:   '#6BAF92',
  meadowT:  '#DAEBE0',
  apricot:  '#F5C49B',
  mulberry: '#9B5C8A',
  mulberryT:'#EBDDE6',

  ink950:   '#0B1220',
  ink700:   '#2A3447',
  ink500:   '#5C657A',
  ink300:   '#A3ABBC',
  line200:  '#E4E7EF',
  line100:  '#EEF1F7',
  surface0: '#FFFFFF',
  surface1: '#FAFBFD',
  surface2: '#F2F4F9',

  success:  '#1F8A5B',
  warning:  '#C97A1A',
  danger:   '#D14343',
};

const SPECIES = [
  { id: 'dog',    label: 'Dog',     accent: TOKENS.coral,    tint: TOKENS.coralT,
    breeds: ['Border Collie', 'Labrador Retriever', 'Golden Retriever', 'French Bulldog',
             'Australian Shepherd', 'Shiba Inu', 'Dachshund', 'Poodle (Standard)',
             'Poodle (Miniature)', 'Cavalier King Charles', 'Beagle', 'Mixed breed',
             'Pomeranian', 'Corgi', 'Cockapoo', 'Bernese Mountain Dog', "Don't know yet"] },
  { id: 'cat',    label: 'Cat',     accent: TOKENS.sunset,   tint: TOKENS.sunsetT,
    breeds: ['Maine Coon', 'British Shorthair', 'Ragdoll', 'Siamese', 'Bengal',
             'Persian', 'Russian Blue', 'Scottish Fold', 'Sphynx', 'Domestic Shorthair',
             'Domestic Longhair', 'Mixed breed', "Don't know yet"] },
  { id: 'rabbit', label: 'Rabbit',  accent: TOKENS.meadow,   tint: TOKENS.meadowT,
    breeds: ['Holland Lop', 'Netherland Dwarf', 'Mini Rex', 'Lionhead', 'Flemish Giant',
             'Dutch', 'English Angora', 'Mixed breed', "Don't know yet"] },
  { id: 'bird',   label: 'Bird',    accent: TOKENS.mulberry, tint: TOKENS.mulberryT,
    breeds: ['Cockatiel', 'Budgerigar', 'African Grey', 'Conure', 'Canary',
             'Lovebird', 'Cockatoo', 'Macaw', 'Finch', "Don't know yet"] },
  { id: 'fish',   label: 'Fish',    accent: TOKENS.blue500,  tint: TOKENS.blue50,
    breeds: ['Betta', 'Goldfish', 'Guppy', 'Tetra', 'Cichlid', 'Angelfish',
             'Discus', 'Mixed tank', "Don't know yet"] },
  { id: 'reptile',label: 'Reptile', accent: TOKENS.apricot,  tint: '#FBEAD7',
    breeds: ['Bearded Dragon', 'Leopard Gecko', 'Ball Python', 'Corn Snake',
             'Crested Gecko', 'Russian Tortoise', "Don't know yet"] },
];

// Pre-existing pets in the user's roster — for the switcher.
const SEED_PETS = [
  { id: 'luna',    name: 'Luna',    species: 'dog',    breed: 'Border Collie',
    accent: TOKENS.coral,    tint: TOKENS.coralT,
    age: '3 yr', healthStreak: 28,    lastSeen: 'on a walk · 8 min ago',
    badge: '2 reminders' },
  { id: 'mochi',   name: 'Mochi',   species: 'cat',    breed: 'Maine Coon',
    accent: TOKENS.sunset,   tint: TOKENS.sunsetT,
    age: '5 yr', healthStreak: 142,   lastSeen: 'napping · 2 hr ago',
    badge: null },
  { id: 'hopper',  name: 'Hopper',  species: 'rabbit', breed: 'Holland Lop',
    accent: TOKENS.meadow,   tint: TOKENS.meadowT,
    age: '1 yr', healthStreak: 9,     lastSeen: 'rest day · just now',
    badge: 'Vet Thu' },
];

Object.assign(window, { TOKENS, SPECIES, SEED_PETS });
