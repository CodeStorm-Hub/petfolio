import * as React from 'react';

export type PillButtonSize = 'sm' | 'md' | 'lg' | 'xl' | 'walk';
export type PillButtonVariant = 'primary' | 'secondary' | 'ghost' | 'destructive' | 'soft';

export interface PrimaryPillButtonProps {
  label: string;
  onPress?: () => void;
  /** Default 'lg' */
  size?: PillButtonSize;
  /** Default 'primary' */
  variant?: PillButtonVariant;
  isLoading?: boolean;
  /** Stretch to full container width */
  isFullWidth?: boolean;
  leadingIcon?: React.ReactNode;
  trailingIcon?: React.ReactNode;
  /** Override accent color (hex/css). Sets bg to this color, text to white */
  color?: string;
  className?: string;
  style?: React.CSSProperties;
}

export declare function PrimaryPillButton(props: PrimaryPillButtonProps): React.ReactElement;
