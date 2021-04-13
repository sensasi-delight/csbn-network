import {Context, Contract, Info, Returns, Transaction} from 'fabric-contract-api';

// const rules = require("./rules.json");

@Info({title: 'Csbn', description: 'Smart contract for Chicken Slaughterhouse blockchain network'})
export class CsbnContract extends Contract {

    @Transaction(false)
    @Returns('string')
    public async reach(): Promise<string> {
        return `Chaincode reached`;
    }

    @Transaction()
    public async createProduct(ctx: Context, id: string, name: string, ingredients: string, halalCertificate: string, manufacturer: string): Promise<void> {
        if (this.validate(ctx, 'createProduct')) {
            throw new Error(`Forbidden action`);
        } else if (await this.isAssetExists(ctx, 'Product', id)) {
            throw new Error(`cant add new record: the asset ID: ${id} is exists`);
        } else {
            const product = {
                ID: id,
                Name: name,
                Ingredients: ingredients,
                HalalCertificate: halalCertificate,
                Manufacturer: manufacturer
            };

            const key = this.getKey(ctx, 'Product', id);
            const data = Buffer.from(JSON.stringify(product));

            await ctx.stub.putState(key, data);
        }
    }

    // returns the product stored in the world state with given id.
    @Transaction(false)
    private async readProduct(ctx: Context, id: string): Promise<string> {
        if (this.validate(ctx, 'readProduct')) {
            throw new Error(`Forbidden action`);
        }
        
        return await this.readAsset(ctx, 'Product', id);
    }

    @Transaction()
    public async updateProduct(ctx: Context, id: string, name: string, ingredients: string, halalCertificate: string, manufacturer: string): Promise<void> {
        if (this.validate(ctx, 'updateProduct')) {
            throw new Error(`Forbidden action`);
        }

        const assetString = await this.readProduct(ctx, id);
        const asset = JSON.parse(assetString);

        asset.Name = name;
        asset.Ingredients = ingredients;
        asset.HalalCertificate = halalCertificate;
        asset.Manufacturer = manufacturer;

        const key = this.getKey(ctx, 'Product', id);
        const data = Buffer.from(JSON.stringify(asset));

        await ctx.stub.putState(key, data);
    }

    @Transaction()
    public async createShip(ctx: Context, id: string, products: string, items: string, location: string): Promise<void> {
        if (this.validate(ctx, 'createShip')) {
            throw new Error(`Forbidden action`);
        }

        if (await this.isAssetExists(ctx, 'Ship', id)) {
            throw new Error(`cant add new record: the ship ID: ${id} is exists`);
        } else {
            const ship = {
                ID: id,
                Products: products,
                Items: items,
                Location: location
            };
    
            const key = this.getKey(ctx, 'Ship', id);
            const data = Buffer.from(JSON.stringify(ship))
    
            await ctx.stub.putState(key, data);
        }
    }

    // returns the product stored in the world state with given id.
    @Transaction(false)
    private async readShip(ctx: Context, id: string): Promise<string> {
        if (this.validate(ctx, 'readShip')) {
            throw new Error(`Forbidden action`);
        }

        return await this.readAsset(ctx, 'Ship', id);
    }

    @Transaction()
    public async updateShip(ctx: Context, id: string, products: string, items: string, location: string): Promise<void> {
        if (this.validate(ctx, 'updateShip')) {
            throw new Error(`Forbidden action`);
        }

        const assetString = await this.readShip(ctx, id);
        const asset = JSON.parse(assetString);
        
        asset.Products = products;
        asset.Items = items;
        asset.Location = location;

        const key = this.getKey(ctx, 'Ship', id);
        const data = Buffer.from(JSON.stringify(asset));
        
        await ctx.stub.putState(key, data);
    }

    @Transaction()
    public async updateShipLocation(ctx: Context, id: string, location: string): Promise<void> {
        if (this.validate(ctx, 'updateShipLocation')) {
            throw new Error(`Forbidden action`);
        }

        const assetString = await this.readShip(ctx, id);
        const asset = JSON.parse(assetString);

        asset.Location = location;

        const key = this.getKey(ctx, 'Ship', id);
        const data = Buffer.from(JSON.stringify(asset));
        
        await ctx.stub.putState(key, data);
    }

    // ReadAsset returns the asset stored in the world state with given id.
    @Transaction(false)
    private async readAsset(ctx: Context, type: string, id: string): Promise<string> {
        const ledgerKey = this.getKey(ctx, type, id);
        const assetJSON = await ctx.stub.getState(ledgerKey); // get the asset from chaincode state
        if (!assetJSON || assetJSON.length === 0) {
            throw new Error(`The ${type} asset ${id} does not exist`);
        }
        return assetJSON.toString();
    }


    // AssetExists returns true when asset with given ID exists in world state.
    @Transaction(false)
    @Returns('boolean')
    public async isAssetExists(ctx: Context, type: string, id: string): Promise<boolean> {
        const key = this.getKey(ctx, type, id);
        const assetJSON = await ctx.stub.getState(key);
        return assetJSON && assetJSON.length > 0;
    }
    
    // GetAllAssets returns all assets found in the world state.
    @Transaction(false)
    @Returns('string')
    public async getAllAssets(ctx: Context, type: string, attrs: string): Promise<string> {
        const allResults = [];

        // range query with empty string for startKey and endKey does an open-ended query of all assets in the chaincode namespace.
        // const iterator = await ctx.stub.getStateByRange(startKey, endKey);
        const iterator = await ctx.stub.getStateByPartialCompositeKey(type, JSON.parse(attrs));

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
            allResults.push({Key: result.value.key, Record: record});
            result = await iterator.next();
        }
        return JSON.stringify(allResults);
    }

    // GetAllAssets returns all assets found in the world state.
    // @Transaction(false)
    // @Returns('string')
    // public async readAssetHistory(ctx: Context, type: string, id: string): Promise<string> {
    //     const allResults = [];

    //     // range query with empty string for startKey and endKey does an open-ended query of all assets in the chaincode namespace.
    //     // const iterator = await ctx.stub.getStateByRange(startKey, endKey);
    //     const key = this.getKey(ctx, 'Ship', id);
    //     const iterator = await ctx.stub.getHistoryForKey(key);

    //     let result = await iterator.next();
    //     while (!result.done) {
    //         const strValue = Buffer.from(result.value.value.toString()).toString('utf8');
    //         let record;
    //         try {
    //             record = JSON.parse(strValue);
    //         } catch (err) {
    //             console.log(err);
    //             record = strValue;
    //         }
    //         allResults.push({Key: result.value.key, Record: record});
    //         result = await iterator.next();
    //     }
    //     return JSON.stringify(allResults);
    // }

    @Transaction(false)
    @Returns('string')
    private getKey(ctx: Context, type: string, id: string) {
        return ctx.stub.createCompositeKey(type, [id]);
        //return type + id;
    }

    @Transaction(false)
    private validate(ctx: Context, functionName: string) {
        // const channelName = ctx.stub.getChannelID();

        // if (channelName != "channel0" && functionName == "createProduct") {
        //     return false;
        // }

        // const orgName = ctx.clientIdentity.getAttributeValue('orgName');

        // const role = rules[channelName][orgName];

        // return rules.roles[role].includes(functionName);
        return true;
    }
}
