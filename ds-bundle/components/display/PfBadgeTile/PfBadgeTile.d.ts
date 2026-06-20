import * as React from 'react';

export interface PfBadgeTileProps {
  emoji: string;
  label: string;
  /** Badge accent color (hex). Used for gradient fill + glow shadow */
  color: string;
  /** Locked badges render greyscale + 45% opacity */
  owned?: boolean;
  className?: string;
  style?: React.CSSProperties;
}

export declare function PfBadgeTile(props: PfBadgeTileProps): React.ReactElement;
