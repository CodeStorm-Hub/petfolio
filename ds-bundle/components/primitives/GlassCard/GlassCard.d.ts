import * as React from 'react';

export interface GlassCardProps {
  children: React.ReactNode;
  /** Corner radius in px. Default 20 (radius-xl token) */
  borderRadius?: number;
  /** Inner padding. Default '16px' */
  padding?: number | string;
  /** Fixed width in px */
  width?: number;
  /** Fixed height in px */
  height?: number;
  /** Accessible label */
  semanticLabel?: string;
  className?: string;
  style?: React.CSSProperties;
}

export declare function GlassCard(props: GlassCardProps): React.ReactElement;
