import * as React from 'react';

export interface PfStatTileProps {
  icon: React.ReactNode;
  value: string;
  label: string;
  backgroundColor: string;
  textColor: string;
  className?: string;
  style?: React.CSSProperties;
}

export declare function PfStatTile(props: PfStatTileProps): React.ReactElement;
