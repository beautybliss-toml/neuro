import { NNS; SNS } "../../src";
import NeuroTypes "../../src/types";

// in production you can use destructuring assignment syntax like:
// import { NNS; SNS; } "mo:neuro";

// or use a namespace import like:
// import Neuro "mo:neuro";

import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Blob "mo:base/Blob";
import Hex "mo:encoding/Hex";
import AccountIdentifier "mo:account-identifier";
import SnsLedgerInterface "../../src/interfaces/sns_ledger_interface";
import IcpLedgerInterface "../../src/interfaces/icp_ledger_interface";

actor class Test() = thisCanister {

    let OPENCHAT_SNS = "2jvtu-yqaaa-aaaaq-aaama-cai";
    let OPENCHAT_LEDGER = "2ouva-viaaa-aaaaq-aaamq-cai";

    let ICP_GOVERNANCE = "rrkah-fqaaa-aaaaa-aaaaq-cai";
    let ICP_LEDGER = "ryjl3-tyaaa-aaaaa-aaaba-cai";

    ///////////////////////////////////
    /// SNS Neuron Staking Example: ///
    ///////////////////////////////////

    public func stake_sns_neuron() : async Result.Result<Blob, Text> {
        let sns = SNS.Governance({
            canister_id = Principal.fromActor(thisCanister);
            sns_canister_id = Principal.fromText(OPENCHAT_SNS);
            sns_ledger_canister_id = Principal.fromText(OPENCHAT_LEDGER);
        });

        // The minimum stake for $CHAT is 400_000_000 e8s.
        // The fee for $CHAT transactions is 100_000 e8s.
        // These values can be obtained by calling the get_nervous_system_parameters and icrc1_fee functions.
        switch (await sns.stake({ amount_e8s = 400_000_000 })) {
            case (#ok result) {
                return #ok(result);
            };
            case (#err result) {
                return #err(result);
            };
        };
    };

    public func list_sns_neurons() : async [NeuroTypes.SnsNeuronInformation] {
        let sns = SNS.Governance({
            canister_id = Principal.fromActor(thisCanister);
            sns_canister_id = Principal.fromText(OPENCHAT_SNS);
            sns_ledger_canister_id = Principal.fromText(OPENCHAT_LEDGER);
        });

        return await sns.listNeurons();
    };

    public func get_sns_neuron_information() : async Result.Result<NeuroTypes.SnsNeuronInformation, Text> {
        let neurons = await list_sns_neurons();

        // In this example, we will retrieve the first neuron from the list of staked neurons.
        // Note: In a real-world application, you might want to store neuron identifiers in local memory
        // or assign specific neurons to users for better management and tracking.
        if (neurons.size() > 0) {
            let ?{ id } = neurons[0].id else return #err("Neuron id not found");

            let neuron = SNS.Neuron({
                neuron_id = id;
                sns_canister_id = Principal.fromText(OPENCHAT_SNS);
            });

            return await neuron.getInformation();
        };

        return #err("No neurons found");
    };

    public func split_sns_neuron() : async Result.Result<NeuroTypes.SnsNeuronId, Text> {
        let neurons = await list_sns_neurons();

        if (neurons.size() > 0) {
            let ?{ id } = neurons[0].id else return #err("Neuron id not found");

            let neuron = SNS.Neuron({
                neuron_id = id;
                sns_canister_id = Principal.fromText(OPENCHAT_SNS);
            });

            return await neuron.split({ amount_e8s = 400_100_000 });
        };

        return #err("No neurons found");
    };

    ///////////////////////////////////
    /// ICP Neuron Staking Example: ///
    ///////////////////////////////////

    // TODO When canisters can control neurons

    //////////////////////////////////////////
    /// Example canister wallet functions: ///
    //////////////////////////////////////////

    public query func get_canister_wallet_information() : async {
        icrc_account : Text;
        icp_legacy_account : Text;
    } {
        return {
            icrc_account = Principal.fromActor(thisCanister) |> Principal.toText(_);
            icp_legacy_account = Principal.fromActor(thisCanister) |> AccountIdentifier.accountIdentifier(_, AccountIdentifier.defaultSubaccount()) |> Blob.toArray(_) |> Hex.encode(_);
        };
    };

    public func get_canister_wallet_balances() : async {
        chat_balance : Nat;
        icp_balance : Nat;
    } {
        let openchatLedger = actor (OPENCHAT_LEDGER) : SnsLedgerInterface.Self;
        let icpLedger = actor (ICP_LEDGER) : IcpLedgerInterface.Self;

        let chatBalance = await openchatLedger.icrc1_balance_of({
            owner = Principal.fromActor(thisCanister);
            subaccount = null;
        });

        let icpBalance = await icpLedger.icrc1_balance_of({
            owner = Principal.fromActor(thisCanister);
            subaccount = null;
        });

        return { chat_balance = chatBalance; icp_balance = icpBalance };
    };
};
