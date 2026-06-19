import * as React from 'react';

export interface SkeletonLoaderProps {
  width: number | 'full';
  height: number;
  /** Corner radius in px. Default 12 (radius-md). Pass 9999 for circle. */
  borderRadius?: number;
  /** 'circle' applies 50% radius regardless of borderRadius */
  shape?: 'rect' | 'circle';
  className?: string;
  style?: React.CSSProperties;
}

export declare function SkeletonLoader(props: SkeletonLoaderProps): React.ReactElement;
