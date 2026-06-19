import * as React from 'react';

export interface PfCardProps {
  children: React.ReactNode;
  /** Inner padding. Number = px, string = any CSS value. Default 16 */
  padding?: number | string;
  /** Corner radius in px. Default 24 (squircle-card token) */
  borderRadius?: number;
  /** Override surface-0 background */
  backgroundColor?: string;
  /** Adds e2 elevation shadow */
  elevated?: boolean;
  /** Removes all shadows */
  flat?: boolean;
  /** Accessible label for screen readers */
  semanticLabel?: string;
  className?: string;
  style?: React.CSSProperties;
}

export declare function PfCard(props: PfCardProps): React.ReactElement;
