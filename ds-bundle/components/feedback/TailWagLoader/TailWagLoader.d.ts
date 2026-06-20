import * as React from 'react';

export interface TailWagLoaderProps {
  size?: number;
  /** Override tangerine default */
  color?: string;
  /** Optional loading label rendered below the dog */
  label?: string;
  className?: string;
  style?: React.CSSProperties;
}

export declare function TailWagLoader(props: TailWagLoaderProps): React.ReactElement;
