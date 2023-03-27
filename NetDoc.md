# Ports

| Port | Description |
| --- | ----------- |
| 8008 | Logger broadcast |
| 20   | Discovery port |
| 21   | ping port |
| 25   | HeartBeat port |
| 30 | Component port |
| 35 | GLasses port |
| 40 | FTP |

# SubscriptionTypes:

| Enum | Description        |
| ---  | -----------        |
| 2    | Threshold          |
| 3    | ThresholdOnChang   |
| 4    | OnChange           |
| 5    | Timer              |

## Threshold
Sends subscriber update when value is either inside or outside a specified range
If value stays in measured range, regular updates are sent on specified Timer

## Threshold On Change

## On Change

## Timer




# Subscription Types:
| Description       | Tag       |
| -----------       | ---       |
| GT Machine Gen    | GT_Gen    |
| GT Power          | GT_Pow    |
| AE Items          | AE_I      |
| AE Fluid          | AE_F      |
| Source Control    | OC_src    |

