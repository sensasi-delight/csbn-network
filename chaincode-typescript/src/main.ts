import { Context, Contract, Info, Returns, Transaction } from 'fabric-contract-api';

import * as rules from "./rules.json";

@Info({ title: 'Csbn', description: 'Smart contract for Chicken Slaughterhouse blockchain network' })
export class CsbnContract extends Contract {

  @Transaction(false)
  @Returns('string')
  public async reach(): Promise<string> {
    return `Chaincode reached`;
  }




  // --------------- ASSET -------------------

  @Transaction()
  public async createOrUpdateAsset(ctx: Context, mode: string, type: string, keysJson: string, dataJson: string): Promise<void> {

    this.isInvalid(ctx, mode + type);

    const keys = JSON.parse(keysJson);
    const isAssetExists = await this.isAssetExists(ctx, type, keys)

    if (isAssetExists && mode == 'create') {
      throw new Error(`cant add new record: the asset ID: ${keys.toString()} is exists`);
    } else if (!isAssetExists && mode == 'update') {
      throw new Error(`cant update record: the asset ID: ${keys.toString()} is not exists`);
    }


    const key = this.getKey(ctx, type, keys);
    const data = Buffer.from(dataJson);

    await ctx.stub.putState(key, data);
  }

  // returns the product stored in the world state with given id.
  @Transaction(false)
  public async readAsset(ctx: Context, type: string, keysJson: string): Promise<string> {

    this.isInvalid(ctx, 'read' + type);

    const keys = JSON.parse(keysJson);

    const ledgerKey = this.getKey(ctx, type, keys);
    const assetJSON = await ctx.stub.getState(ledgerKey);

    if (!assetJSON || assetJSON.length === 0) {
      throw new Error(`The ${type} asset ${keys.toString()} does not exist`);
    }

    return assetJSON.toString();
  }


  // GetAllAssets returns all assets found in the world state.
  @Transaction(false)
  @Returns('string')
  public async readAssets(ctx: Context, type: string, keysJson: string): Promise<string> {

    this.isInvalid(ctx, 'read' + type);

    const allResults = [];
    const keys = JSON.parse(keysJson);

    // const iterator = await ctx.stub.getStateByRange(topKey, bottomKey); composite key can't getStateByRange
    const iterator = await ctx.stub.getStateByPartialCompositeKey(type, keys);

    let result = await iterator.next();
    while (!result.done) {
      const strValue = Buffer.from(result.value.value.toString()).toString('utf8');
      let record;
      try {
        record = JSON.parse(strValue);
      } catch (err) {
        console.log(err);
        record = strValue;
      }
      allResults.push({ Key: result.value.key, Record: record });
      result = await iterator.next();
    }
    return JSON.stringify(allResults);
  }




  // DeleteAsset deletes an given asset from the world state.
  @Transaction()
  public async deleteAsset(ctx: Context, type: string, keysJson: string): Promise<void> {

    const keys = JSON.parse(keysJson);

    const exists = await this.isAssetExists(ctx, type, keys);
    if (!exists) {
      throw new Error(`The ${type} asset ${keys.toString()} does not exist`);
    }

    const ledgerKey = this.getKey(ctx, type, keys);
    return ctx.stub.deleteState(ledgerKey);
  }


  @Transaction(false)
  @Returns('string')
  public async getAssetHistory(ctx: Context, type: string, keysJsonStr: string): Promise<string> {

    const keys: Array<string> = JSON.parse(keysJsonStr);

    const ledgerKey: string = this.getKey(ctx, type, keys);

    const promiseOfIterator = ctx.stub.getHistoryForKey(ledgerKey);

    const results: Array<Object> = [];
    
    for await (const keyMod of promiseOfIterator) {
      const resp: any = {};

      resp.timestamp = keyMod.timestamp;
      resp.txId = keyMod.txId;
      resp.isDelete = keyMod.isDelete;

      if (!keyMod.isDelete) {
        resp.data = keyMod.value.toString('utf8');
      }

      results.push(resp);
    }

    return JSON.stringify(results);
  }



  // ------------ PRIVATE --------------------

  // AssetExists returns true when asset with given ID exists in world state.
  @Transaction(false)
  @Returns('boolean')
  private async isAssetExists(ctx: Context, type: string, attributes: string[]): Promise<boolean> {
    const key = this.getKey(ctx, type, attributes);
    const assetJSON = await ctx.stub.getState(key);
    return assetJSON && assetJSON.length > 0;
  }

  @Transaction(false)
  @Returns('string')
  private getKey(ctx: Context, type: string, attributes: string[]): string {
    return ctx.stub.createCompositeKey(type, attributes);
  }

  @Transaction(false)
  private isInvalid(ctx: Context, functionName: string) {
    const channelName = ctx.stub.getChannelID();
    const MspId = ctx.clientIdentity.getMSPID();
    const role = rules.channels[channelName][MspId];


    const channel0FunctionOnly = [
      "createProduct",
      "readProduct",
      "updateProduct",

      "createBatch",
      "updateBatch",
      "readBatch",

      "createSlaughterer",
      "readSlaughterer",
      "updateSlaughterer"
    ];

    if (channelName == "channel0" && !channel0FunctionOnly.includes(functionName)) {
      throw new Error(`Forbidden action: can't execute ` + functionName + ' on ' + channelName);
    }

    if (channelName != "channel0" && channel0FunctionOnly.includes(functionName)) {
      throw new Error(`Forbidden action: can't execute ` + functionName + ' on ' + channelName);
    }

    if (!rules.roles[role].includes(functionName)) {
      throw new Error(`Forbidden action: ` + role + ` role can't execute ` + functionName);
    }
  }
}
