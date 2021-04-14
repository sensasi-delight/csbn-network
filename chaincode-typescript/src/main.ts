import {Context, Contract, Info, Returns, Transaction} from 'fabric-contract-api';

import * as rules from "./rules.json";

@Info({title: 'Csbn', description: 'Smart contract for Chicken Slaughterhouse blockchain network'})
export class CsbnContract extends Contract {

    @Transaction(false)
    @Returns('string')
    public async reach(): Promise<string> {
        return `Chaincode reached`;
    }

    @Transaction()
    public async createProduct(ctx: Context, id: string, name: string, ingredients: string, halalCertificate: string, manufacturer: string, orgName: string): Promise<void> {
        if (!this.isValid(ctx, 'createProduct')) {
            throw new Error(`Forbidden action`);
        } else if (await this.isAssetExists(ctx, 'Product', [id, orgName])) {
            throw new Error(`cant add new record: the asset ID: ${id} is exists`);
        } else {
            const product = {
                id: id,
                name: name,
                ingredients: ingredients,
                halalCertificate: halalCertificate,
                manufacturer: manufacturer
            };

            const key = this.getKey(ctx, 'Product', [id, orgName]);
            const data = Buffer.from(JSON.stringify(product));

            await ctx.stub.putState(key, data);
        }
    }

    // returns the product stored in the world state with given id.
    @Transaction(false)
    public async readProduct(ctx: Context, id: string, orgName: string): Promise<string> {
        if (!this.isValid(ctx, 'readProduct')) {
            throw new Error(`Forbidden action`);
        }
        
        return await this.readAsset(ctx, 'Product', [id, orgName]);
    }

    @Transaction()
    public async updateProduct(ctx: Context, id: string, name: string, ingredients: string, halalCertificate: string, manufacturer: string, orgName: string): Promise<void> {
        if (!this.isValid(ctx, 'updateProduct')) {
            throw new Error(`Forbidden action`);
        }

        const assetString = await this.readProduct(ctx, id, orgName);
        const asset = JSON.parse(assetString);

        asset.name = name;
        asset.ingredients = ingredients;
        asset.halalCertificate = halalCertificate;
        asset.manufacturer = manufacturer;

        const key = this.getKey(ctx, 'Product', [id, orgName]);
        const data = Buffer.from(JSON.stringify(asset));

        await ctx.stub.putState(key, data);
    }

    @Transaction()
    public async createShipment(ctx: Context, id: string, productsState: string, items: string, location: string): Promise<void> {
        if (!this.isValid(ctx, 'createShipment')) {
            throw new Error(`Forbidden action`);
        }

        if (await this.isAssetExists(ctx, 'Shipment', [id])) {
            throw new Error(`cant add new record: the shipment ID: ${id} is exists`);
        } else {
            const shipment = {
                id: id,
                productsState: productsState,
                items: items,
                location: location
            };
    
            const key = this.getKey(ctx, 'Shipment', [id]);
            const data = Buffer.from(JSON.stringify(shipment))
    
            await ctx.stub.putState(key, data);
        }
    }

    // returns the product stored in the world state with given id.
    @Transaction(false)
    public async readShipment(ctx: Context, id: string): Promise<string> {
        if (!this.isValid(ctx, 'readShipment')) {
            throw new Error(`Forbidden action`);
        }

        return await this.readAsset(ctx, 'Shipment', [id]);
    }

    @Transaction()
    public async updateShipment(ctx: Context, id: string, productsState: string, items: string, location: string): Promise<void> {
        if (!this.isValid(ctx, 'updateShipment')) {
            throw new Error(`Forbidden action`);
        }

        const assetString = await this.readShipment(ctx, id);
        const asset = JSON.parse(assetString);
        
        asset.productsState = productsState;
        asset.items = items;
        asset.location = location;

        const key = this.getKey(ctx, 'Shipment', [id]);
        const data = Buffer.from(JSON.stringify(asset));
        
        await ctx.stub.putState(key, data);
    }

    @Transaction()
    public async updateShipmentLocation(ctx: Context, id: string, location: string): Promise<void> {
        if (!this.isValid(ctx, 'updateShipmentLocation')) {
            throw new Error(`Forbidden action`);
        }

        const assetString = await this.readShipment(ctx, id);
        const asset = JSON.parse(assetString);

        asset.location = location;

        const key = this.getKey(ctx, 'Shipment', [id]);
        const data = Buffer.from(JSON.stringify(asset));
        
        await ctx.stub.putState(key, data);
    }

    // ReadAsset returns the asset stored in the world state with given id.
    @Transaction(false)
    private async readAsset(ctx: Context, type: string, attributes: string[]): Promise<string> {
        const ledgerKey = this.getKey(ctx, type, attributes);
        const assetJSON = await ctx.stub.getState(ledgerKey); // get the asset from chaincode state
        if (!assetJSON || assetJSON.length === 0) {
            throw new Error(`The ${type} asset ${attributes[0]} does not exist`);
        }
        return assetJSON.toString();
    }


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
    private getKey(ctx: Context, type: string, attributes: string[]) {
        return ctx.stub.createCompositeKey(type, attributes);
    }

    @Transaction(false)
    private isValid(ctx: Context, functionName: string) {
        const channelName = ctx.stub.getChannelID();

        const channel0FunctionOnly = [
            "createProduct",
            "updateProduct",
            "readProduct"
        ];

        if (channelName == "channel0" && !channel0FunctionOnly.includes(functionName)) {
            return false;
        }

        if (channelName != "channel0" && channel0FunctionOnly.includes(functionName)) {
            return false;
        }

        ctx.clientIdentity.getMSPID();

        const MSPID = ctx.clientIdentity.getMSPID();

        const role = rules.channels[channelName][MSPID];

        return rules.roles[role].includes(functionName);
    }
}
