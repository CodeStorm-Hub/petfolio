import * as React from 'react';

export interface PawToggleProps {
  value: boolean;
  onChanged?: (value: boolean) => void;
  /** Override tangerine active color */
  activeColor?: string;
  semanticLabel?: string;
  className?: string;
  style?: React.CSSProperties;
}

export declare function PawToggle(props: PawToggleProps): React.ReactElement;
