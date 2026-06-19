import * as React from 'react';

export type PetAvatarSize = 'sm' | 'md' | 'lg' | 'xl' | 'xxl';
export type PetSpecies = 'dog' | 'cat' | 'bird' | 'rabbit' | 'other';

export interface PetAvatarProps {
  /** Remote image URL */
  imageUrl?: string;
  species?: PetSpecies;
  /** Default 'md' (40px) */
  size?: PetAvatarSize;
  /** Shows online/offline status dot */
  isOnline?: boolean;
  semanticLabel?: string;
  /** Up to 2 characters shown when no image */
  initials?: string;
  /** Rainbow gradient ring */
  showRing?: boolean;
  /** Solid border color override */
  borderColor?: string;
  onTap?: () => void;
  className?: string;
  style?: React.CSSProperties;
}

export declare function PetAvatar(props: PetAvatarProps): React.ReactElement;
